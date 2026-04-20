defmodule ElixirAndrewWeb.Student.SpellingGames.Crossword.CrosswordGenerator do
  alias ElixirAndrewWeb.Student.AI.Service
  alias ElixirAndrew.ClassSession
  require Logger

  @grid_size 15
  @candidate_limit 20
  @parallel_branches 3 
  @min_words 10 


  @spec get_crossword_clues(list(String.t()), map()) :: {:ok, list(map())} | {:error, term()}
  def get_crossword_clues(spelling_words, progress) do
    Logger.info("=== Crossword Generator Test ===")
    Logger.info("Original spelling words (#{length(spelling_words)}): #{inspect(spelling_words)}")
    
    # Pad word list if needed
    padded_words = pad_word_list(spelling_words, progress)

    # TEMPORARY: Return mock data to test without AI call
    mock_words_with_clues = Enum.map(padded_words, fn word ->
      %{"word" => word, "clue" => "Mock clue for #{word}"}
    end)
    
    Logger.info("✓ Returning mock data (AI call skipped)")
    {:ok, mock_words_with_clues}

    # Uncomment below to make actual AI call:
    # case Service.get_crossword_clues(padded_words, progress, max_words: 12) do
    #   {:ok, %{"words" => words_with_clues}} ->
    #     Logger.info("✓ AI Response received!")
    #     Logger.info("Words with clues: #{inspect(words_with_clues, pretty: true)}")
    #     {:ok, words_with_clues}
    
    #   {:error, reason} ->
    #     Logger.error("✗ AI call failed: #{inspect(reason)}")
    #     {:error, reason}
    # end
  end
  
  defp pad_word_list(words, progress) when length(words) >= @min_words, do: words
  
  defp pad_word_list(words, progress) do
    needed = @min_words - length(words)
    
    # Get previous spelling words from student's class sessions
    student_id = Map.get(progress, :user_id)
    
    previous_words = if student_id do
      ClassSession.list_class_sessions(student_id, 10)  # Get last 10 sessions
      |> Enum.flat_map(fn session -> session.spelling_words || [] end)
      |> Enum.reject(fn word -> word in words end)  # Remove duplicates
      |> Enum.sort_by(&String.length/1, :desc)  # Prioritize longer words
      |> Enum.take(needed)
    else
      []
    end
    
    words ++ previous_words
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
    
    # Give more room - at least longest word + 4 for better placement options
    dynamic_grid_size = max(longest_word_length + 4, @grid_size)
    
    Logger.info("Grid size: #{dynamic_grid_size}")

    state = %{
      grid: %{},
      placements: [],
      grid_size: dynamic_grid_size,
      grid_rows: dynamic_grid_size,
      grid_cols: dynamic_grid_size
    }

    case solve(state, entries) do
      {:ok, final_state} -> 
        Logger.info("✓ Successfully placed #{length(final_state.placements)} words")
        
        # Compact the grid by removing empty rows/columns
        compacted_state = compact_grid(final_state)
        
        {:ok, %{compacted_state | placements: sort_and_number_wordlist(compacted_state.placements)}}
      :fail -> 
        Logger.error("✗ Failed to place all words (only placed #{length(state.placements)})")
        :fail
    end
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
    
    case try_placements(state, entry, rest, placements) do
      {:ok, result} -> {:ok, result}
      :fail -> 
        Logger.debug("✗ Failed to place '#{word}'")
        :fail
    end
  end
  
  defp try_placements(_state, _entry, _rest, []), do: :fail
  
  defp try_placements(state, entry, rest, placements) do
    # Try placements sequentially with early termination
    placements
    |> Enum.take(@candidate_limit)
    |> Enum.reduce_while(:fail, fn placement, _acc ->
      new_state = place_word(state, entry, placement)
      
      case solve(new_state, rest) do
        {:ok, result} -> {:halt, {:ok, result}}
        :fail -> {:cont, :fail}
      end
    end)
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
  
  # Compact grid by removing empty rows/columns and shifting coordinates
  defp compact_grid(state) do
    if map_size(state.grid) == 0 do
      state
    else
      # Find bounding box of all placed letters
      {min_row, max_row, min_col, max_col} = bounding_box(state.grid)
      
      row_offset = min_row
      col_offset = min_col
      
      # Shift grid coordinates
      new_grid = 
        state.grid
        |> Enum.map(fn {{r, c}, letter} -> {{r - row_offset, c - col_offset}, letter} end)
        |> Map.new()
      
      # Shift placement coordinates
      new_placements = 
        Enum.map(state.placements, fn placement ->
          %{placement | row: placement.row - row_offset, col: placement.col - col_offset}
        end)
      
      grid_rows = max_row - min_row + 1
      grid_cols = max_col - min_col + 1
      
      %{state | 
        grid: new_grid, 
        placements: new_placements, 
        grid_rows: grid_rows, 
        grid_cols: grid_cols
      }
    end
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

  defp sort_and_number_wordlist(placements) do
    # Sort by row then column (reading order)
    sorted = Enum.sort_by(placements, fn p -> {p.row, p.col} end)
    
    # Group by starting position to assign shared numbers
    sorted
    |> Enum.reduce({[], %{}, 1}, fn placement, {numbered, position_map, next_num} ->
      position = {placement.row, placement.col}
      
      {number, new_map, new_next} = 
        case Map.get(position_map, position) do
          nil -> 
            # New position, assign new number
            {next_num, Map.put(position_map, position, next_num), next_num + 1}
          existing_num -> 
            # Same position as previous word, reuse number
            {existing_num, position_map, next_num}
        end
      
      numbered_placement = Map.put(placement, :number, number)
      {[numbered_placement | numbered], new_map, new_next}
    end)
    |> elem(0)
    |> Enum.reverse()
  end
end