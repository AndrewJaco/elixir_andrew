defmodule ElixirAndrewWeb.Student.SpellingGames.CrosswordGenerator do
  alias ElixirAndrewWeb.Student.AI.Service
  require Logger

  @grid_size 15
  @candidate_limit 6
  @parallel_branches 4
  @max_span 12


  @spec get_crossword_clues(list(String.t()), map()) :: {:ok, list(map())} | {:error, term()}
  def get_crossword_clues(spelling_words, progress) do
    Logger.info("=== Crossword Generator Test ===")
    Logger.info("Spelling words: #{inspect(spelling_words)}")

    # TEMPORARY: Return mock data to test without AI call
    mock_words_with_clues = Enum.map(spelling_words, fn word ->
      %{"word" => word, "clue" => "Mock clue for #{word}"}
    end)
    
    Logger.info("✓ Returning mock data (AI call skipped)")
    {:ok, mock_words_with_clues}

    # Uncomment below to make actual AI call:
    # case Service.get_crossword_clues(spelling_words, progress, max_words: 12) do
    #   {:ok, %{"words" => words_with_clues}} ->
    #     Logger.info("✓ AI Response received!")
    #     Logger.info("Words with clues: #{inspect(words_with_clues, pretty: true)}")
    #     {:ok, words_with_clues}
    
    #   {:error, reason} ->
    #     Logger.error("✗ AI call failed: #{inspect(reason)}")
    #     {:error, reason}
    # end
  end

  def generate(words_clues) do
    entries = 
      words_clues
      |> Enum.map(fn %{"word" => word, "clue" => clue} -> 
        %{word: normalize_word(word), clue: clue}
      end)
      |> Enum.sort_by(&String.length(&1.word), :desc)

    # Calculate grid size based on longest word (with some padding)
    longest_word_length = 
      entries
      |> Enum.map(&String.length(&1.word))
      |> Enum.max(fn -> 0 end)
    
    # Grid size should be at least the longest word length + 2 for padding
    dynamic_grid_size = max(longest_word_length + 2, @grid_size)

    state = %{
      grid: %{},
      placements: [],
      grid_size: dynamic_grid_size
    }

    solve(state, entries)
  end
    
  defp normalize_word(word) do
    word
    |> String.replace(" ", "")
    |> String.upcase()
  end

  #recursive solver
  defp solve(state, []), do: {:ok, state}

  defp solve(state, [entry | rest]) do
    word = entry.word
    placements =
      generate_candidates(word, state.grid, state.grid_size)
      |> Enum.sort_by(&score(word, &1, state.grid), :desc)
      |> Enum.take(@candidate_limit)
      
    try_placements(state, entry, rest, placements)
  end
  
  defp try_placements(_state, _entry, _rest, []), do: :fail
  
  defp try_placements(state, entry, rest, placements) do
    placements
    |> Enum.take(@parallel_branches)
    |> Task.async_stream(
      fn placement -> 
        new_state = place_word(state, entry, placement)

        case solve(new_state, rest) do
          {:ok, result} -> {:ok, result}
          _ -> :fail
        end
      end,
      timeout: 5000,
      ordered: false
    )
    |> Enum.find_value(fn
      {:ok, {:ok, result}} -> {:ok, result}
      _ -> nil
    end)
    |> case do
      nil -> :fail
      result -> result
    end
  end

  # candidate generation
  defp generate_candidates(word, grid, grid_size) do
    if map_size(grid) == 0 do
      center_candidates(word, grid_size)
    else
      generate_anchor_candidates(word, grid, grid_size)
      |> Enum.filter(&valid_placement?(word, &1, grid, grid_size))
    end
  end

  defp center_candidates(word, grid_size) do
    row = div(grid_size, 2)
    col = div(grid_size, 2) - div(String.length(word), 2)
    
    # With dynamic grid sizing, this should always be valid
    [%{row: row, col: col, dir: :across}]
  end

  # anchor placements
  defp generate_anchor_candidates(word, grid, _grid_size) do
    anchors = Map.keys(grid)
    
    anchors
    |> Enum.flat_map(fn {r, c} ->
      anchor_letter = Map.get(grid, {r, c})

      matching_indices(word, anchor_letter)
      |> Enum.flat_map(fn idx ->
        [
          %{row: r, col: c - idx, dir: :across},
          %{row: r - idx, col: c, dir: :down}
        ]
        end)
    end)
  end

  defp matching_indices(word, letter) do
    word
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.filter(fn {l, _} -> l == letter end)
    |> Enum.map(fn {_, idx} -> idx end)
  end

  # placement validation
  defp valid_placement?(word, placement, grid, grid_size) do 
    letters = String.graphemes(word)
    word_length = length(letters)

    # Check endpoints are clear (no letters before/after word in same direction)
    {start_check, end_check} = case placement.dir do
      :across -> 
        {{placement.row, placement.col - 1}, {placement.row, placement.col + word_length}}
      :down -> 
        {{placement.row - 1, placement.col}, {placement.row + word_length, placement.col}}
    end
    
    endpoints_clear = 
      not Map.has_key?(grid, start_check) and
      not Map.has_key?(grid, end_check)

    # Check each letter position
    letters_valid = 
      Enum.with_index(letters)
      |> Enum.all?(fn {letter, i} ->
        {r, c} = 
          case placement.dir do
            :across -> {placement.row, placement.col + i}
            :down -> {placement.row + i, placement.col}
          end

        cell_value = Map.get(grid, {r, c})

        cond do
          # Out of bounds
          not within_bounds?(r, c, grid_size) -> false
          
          # Intersection - must match existing letter
          cell_value != nil and cell_value != letter -> false
          
          # Intersection with matching letter - OK, skip other checks
          cell_value == letter -> true
          
          # New letter - check no perpendicular adjacencies
          true -> not has_perpendicular_adjacency?(r, c, placement.dir, grid)
        end
      end)

    endpoints_clear and letters_valid
  end

  defp within_bounds?(r, c, grid_size) do
    r >= 0 and r < grid_size and c >= 0 and c < grid_size
  end

  defp has_perpendicular_adjacency?(r, c, dir, grid) do
    # Check perpendicular directions only to avoid parallel word collisions
    adjacent_coords = case dir do
      :across -> [{r - 1, c}, {r + 1, c}]  # Check above/below
      :down -> [{r, c - 1}, {r, c + 1}]    # Check left/right
    end

    Enum.any?(adjacent_coords, fn coord ->
      Map.has_key?(grid, coord)
    end)
  end
    
  # placement scoring
  defp score(word, placement, grid) do
    intersections = 
      String.graphemes(word)
      |> Enum.with_index()
      |> Enum.count(fn {letter, i} ->
        {r, c} = 
          case placement.dir do
            :across -> {placement.row, placement.col + i}
            :down -> {placement.row + i, placement.col}
          end
        
        Map.get(grid, {r, c}) == letter
      end)

      compaction = compaction_score(placement, grid)

      intersections * 10 + compaction * 2 - String.length(word)
  end

  defp compaction_score(_placement, grid) when map_size(grid) == 0, do: 0

  defp compaction_score(placement, grid) do
    {min_r, max_r, min_c, max_c} = bounding_box(grid)

    cond do
      placement.row >= min_r and placement.row <= max_r and
        placement.col >= min_c and placement.col <= max_c ->
        3

      true ->
        0
    end
  end

  # grid utilities
  defp bounding_box(grid) do
    coords = Map.keys(grid)

    rows = Enum.map(coords, fn {r, _} -> r end)
    cols = Enum.map(coords, fn {_, c} -> c end)

    {Enum.min(rows), Enum.max(rows), Enum.min(cols), Enum.max(cols)}
  end

  # word placement
  defp place_word(state, entry, placement) do
    word = entry.word
    letters = String.graphemes(word)

    new_grid =
      Enum.with_index(letters)
      |> Enum.reduce(state.grid, fn {letter, i}, grid ->
        {r, c} = 
          case placement.dir do
            :across -> {placement.row, placement.col + i}
            :down -> {placement.row + i, placement.col}
          end

        Map.put(grid, {r, c}, letter)
      end)

      placed_entry = 
        Map.merge(entry, %{
          row: placement.row,
          col: placement.col,
          direction: placement.dir,
          length: String.length(word)
        })

      %{
        state
        | grid: new_grid,
          placements: [placed_entry | state.placements]
      }
  end
end