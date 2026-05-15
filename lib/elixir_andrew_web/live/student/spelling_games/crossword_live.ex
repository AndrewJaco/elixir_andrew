defmodule ElixirAndrewWeb.Student.SpellingGames.CrosswordLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.Crossword.{PlacedWord, ClueCache, CrosswordGenerator}
  require Logger

  @impl true
  def mount(params, session, socket) do
    spelling_words = case params["spelling_words"] do
      nil -> []
      words when is_binary(words) -> 
        words
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      words when is_list(words) -> words
    end
    
    # Check if clues were pre-generated and retrieve from cache
    pregenerated_clues = case params["clue_cache_key"] do
      key when is_binary(key) -> ClueCache.pop(key)
      _ -> nil
    end
    
    socket =
      socket
      |> assign(:spelling_words, spelling_words)
      |> assign(:game_state, if(pregenerated_clues, do: :ready, else: :loading))
      |> assign(:error, nil)
      |> assign(:words_with_clues, pregenerated_clues)
      |> assign(:grid_state, nil)
      |> assign(:grid_rows, nil)
      |> assign(:grid_cols, nil)
      |> assign(:placed_wordlist, [])
      |> assign(:initialized, false)
      |> assign(:solved, false)

    # Only initialize on first mount, not on reconnects
    if connected?(socket) and not socket.assigns.initialized do
      if pregenerated_clues do
        send(self(), :generate_grid)
      else
        # No clues - either debug link or navigation error
        send(self(), :initialize_game)
      end
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:initialize_game, socket) do
    Logger.info("Initializing crossword game (generating clues)...")
    
    spelling_words = socket.assigns.spelling_words
    user_id = socket.assigns.current_user.id

    socket = 
      case ElixirAndrew.Progress.get_user_progress(user_id) do
        nil ->
          Logger.error("No progress found for user #{user_id}")
          assign(socket, game_state: :error, error: "No progress found", initialized: true)
        
        progress ->
          # Generate clues first
          case CrosswordGenerator.get_crossword_clues(spelling_words, progress) do
            {:ok, clues} ->
              Logger.info("✓ Clues generated, now generating grid...")
              send(self(), :generate_grid)
              assign(socket, words_with_clues: clues, game_state: :loading)
            
            {:error, reason} ->
              Logger.error("✗ Failed to generate clues: #{inspect(reason)}")
              assign(socket, game_state: :error, error: reason, initialized: true)
          end
      end

    {:noreply, socket}
  end
  
  @impl true  
  def handle_info(:generate_grid, socket) do
    Logger.info("Generating crossword grid...")
    
    words_with_clues = socket.assigns.words_with_clues
    
    socket = case CrosswordGenerator.generate(words_with_clues) do
      {:ok, grid_state} ->
        Logger.info("✓ Grid generated successfully!")
        
        # Convert sparse grid to full 2D array
        full_grid = build_full_grid(grid_state.grid, grid_state.grid_rows, grid_state.grid_cols, grid_state.placements)

        selected_word = List.first(grid_state.placements)
        first_cell = selected_word && List.first(get_word_cells(selected_word))
        
        socket
        |> assign(:grid_state, full_grid)
        |> assign(:placed_wordlist, grid_state.placements)
        |> assign(:grid_rows, grid_state.grid_rows)
        |> assign(:grid_cols, grid_state.grid_cols)
        |> assign(:user_input, initialize_user_input(grid_state.placements))
        |> assign(:selected_word, selected_word)
        |> assign(:selected_direction, selected_word && selected_word.direction)
        |> assign(:current_cell, first_cell)
        |> assign(:game_state, :in_progress)
        |> assign(:initialized, true)
      
      :fail ->
        Logger.error("✗ Failed to generate grid layout")
        socket
        |> assign(:game_state, :error)
        |> assign(:error, "Could not create crossword layout")
        |> assign(:initialized, true)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("back_to_game", _params, socket) do
    {:noreply, assign(socket, :game_state, :in_progress)}
  end
  
  @impl true
  def handle_event("check_puzzle", _params, socket) do
    # Compare user_input with actual grid
    socket = assign(socket, :current_cell, nil)
    |> assign(:selected_word, nil)

    socket = if Enum.all?(socket.assigns.grid_state, fn cell ->
      if cell.filled do
        Map.get(socket.assigns.user_input, {cell.row, cell.col}) == cell.letter
      else
        true
      end
    end)
    do
      Logger.info("Puzzle solved!")
      assign(socket, :game_state, :correct)
    else
      Logger.info("Puzzle not solved yet.")
      assign(socket, :game_state, :try_again)
    end
    
    {:noreply, socket}
  end
  
  def handle_event("clear_puzzle", _params, socket) do
    socket = assign(socket, :user_input, %{})
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("handle_key", %{"key" => key}, socket) do
    cond do
      # Letter key
      String.match?(key, ~r/^[a-zA-Z]$/) ->
        handle_letter_input(socket, String.upcase(key))
      
      # Backspace
      key == "Backspace" ->
        handle_backspace(socket)
      
      # Arrow keys for navigation
      key in ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"] ->
        handle_arrow_key(socket, key)
      
      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reveal_puzzle", _params, socket) do
    # Fill in all answers
    user_input = 
      socket.assigns.grid_state
      |> Enum.filter(& &1.filled)
      |> Enum.map(fn cell -> {{cell.row, cell.col}, cell.letter} end)
      |> Map.new()

    socket = assign(socket, :user_input, user_input)
    |> assign(:game_state, :solved)
    |> assign(:current_cell, nil)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_cell", %{"row" => row_str, "col" => col_str}, socket) do
    row = String.to_integer(row_str)
    col = String.to_integer(col_str)
    
    # Find which word(s) contain this cell
    words_at_cell = Enum.filter(socket.assigns.placed_wordlist, fn word ->
      cells = get_word_cells(word)
      {row, col} in cells
    end)
    
    # If clicking same cell, toggle direction; otherwise select first word
    selected_word = case {socket.assigns.current_cell, words_at_cell} do
      {{^row, ^col}, [word1, word2]} ->
        # Same cell clicked, toggle between across/down
        if socket.assigns.selected_word == word1, do: word2, else: word1
      
      {_, [word | _]} ->
        word
      
      _ ->
        nil
    end
    
    socket = socket
      |> assign(:selected_word, selected_word)
      |> assign(:current_cell, {row, col})
    
    # Focus mobile input when a word is selected
    socket = if selected_word do
      push_event(socket, "focus-mobile-input", %{})
    else
      socket
    end
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("mobile_key_input", %{"key" => key}, socket) do
    cond do
      String.match?(key, ~r/^[A-Z]$/) ->
        handle_letter_input(socket, key)
      
      key == "Backspace" ->
        handle_backspace(socket)
      
      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_word", %{"number" => number_str, "direction" => direction_str}, socket) do
    number = String.to_integer(number_str)
    direction = String.to_atom(direction_str)
    
    selected_word = Enum.find(socket.assigns.placed_wordlist, fn word ->
      word.number == number and word.direction == direction
    end)
    
    socket = assign(socket, :selected_word, selected_word)
    |> assign(:current_cell, List.first(get_word_cells(selected_word)))
    
    {:noreply, socket}
  end

  defp handle_letter_input(socket, letter) do
    if socket.assigns.selected_word && socket.assigns.current_cell do
      {row, col} = socket.assigns.current_cell
      
      # Update user input
      new_input = Map.put(socket.assigns.user_input, {row, col}, letter)
      
      # Move to next cell in word
      next_cell = get_next_cell_in_word(socket.assigns.selected_word, {row, col})
      
      socket = socket
        |> assign(:user_input, new_input)
        |> assign(:current_cell, next_cell)
      
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end
  
  defp handle_backspace(socket) do
    if socket.assigns.selected_word && socket.assigns.current_cell do
      {row, col} = socket.assigns.current_cell
      
      # Clear current cell and move back
      new_input = Map.delete(socket.assigns.user_input, {row, col})
      prev_cell = get_prev_cell_in_word(socket.assigns.selected_word, {row, col})
      
      socket = socket
        |> assign(:user_input, new_input)
        |> assign(:current_cell, prev_cell)
      
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end
  
  defp handle_arrow_key(socket, key) do
    key_to_direction = %{
      "ArrowLeft" => :left,
      "ArrowRight" => :right,
      "ArrowUp" => :up,
      "ArrowDown" => :down
    }
    direction = key_to_direction[key]
    if socket.assigns.selected_word && socket.assigns.current_cell do
      {row, col} = socket.assigns.current_cell
      
      next_cell = case direction do
        :left -> {row, col - 1}
        :right -> {row, col + 1}
        :up -> {row - 1, col}
        :down -> {row + 1, col}
      end
      
      # Check if next cell is part of the selected word
      if next_cell in get_word_cells(socket.assigns.selected_word) do
        socket = assign(socket, :current_cell, next_cell)
        {:noreply, socket}
      else
        # Try to find a word in the direction of movement
        case find_nearest_word(socket.assigns.current_cell, direction, socket) do
          nil ->
            # No word found in that direction, stay put
            {:noreply, socket}
          
          new_current_word ->
            new_current_cell = 
              get_word_cells(new_current_word) 
              |> Enum.find(fn cell -> cell == next_cell end) 
              || List.first(get_word_cells(new_current_word))
            
            socket = socket
              |> assign(:selected_word, new_current_word)
              |> assign(:current_cell, new_current_cell)
            {:noreply, socket}
        end
      end
    else
      {:noreply, socket}
    end
  end

  defp find_nearest_word(current_cell, direction, socket) do
    {row, col} = current_cell || {0, 0}
    
    # Find words that have cells in the given direction
    candidate_words = 
      socket.assigns.placed_wordlist
      |> Enum.map(fn word ->
        cells = get_word_cells(word)
        
        # Calculate minimum distance to any cell in this word in the given direction
        distance = 
          cells
          |> Enum.map(fn {r, c} ->
            case direction do
              :left -> if r == row and c < col, do: col - c, else: :infinity
              :right -> if r == row and c > col, do: c - col, else: :infinity
              :up -> if r < row and c == col, do: row - r, else: :infinity
              :down -> if r > row and c == col, do: r - row, else: :infinity
            end
          end)
          |> Enum.min()
        
        {word, distance}
      end)
      |> Enum.reject(fn {_word, distance} -> distance == :infinity end)
    
    # Return the word with minimum distance, or nil if no candidates
    case candidate_words do
      [] -> nil
      words -> words |> Enum.min_by(fn {_word, distance} -> distance end) |> elem(0)
    end
  end
  
  defp initialize_user_input(_placements) do
    %{}  # Empty map, keys are {row, col}, values are letters
  end
  
  defp get_word_cells(word) do
    for i <- 0..(word.length - 1) do
      case word.direction do
        :across -> {word.row, word.col + i}
        :down -> {word.row + i, word.col}
      end
    end
  end
  
  defp get_next_cell_in_word(word, {row, col}) do
    cells = get_word_cells(word)
    current_index = Enum.find_index(cells, fn cell -> cell == {row, col} end)
    
    if current_index && current_index < length(cells) - 1 do
      Enum.at(cells, current_index + 1)
    else
      {row, col}  # Stay at current if at end
    end
  end
  
  defp get_prev_cell_in_word(word, {row, col}) do
    cells = get_word_cells(word)
    current_index = Enum.find_index(cells, fn cell -> cell == {row, col} end)
    
    if current_index && current_index > 0 do
      Enum.at(cells, current_index - 1)
    else
      {row, col}  # Stay at current if at beginning
    end
  end

  defp new_game(socket) do
    # Clear cache if there was a clue_cache_key
    if key = socket.assigns[:clue_cache_key] do
      ClueCache.pop(key)
    end

    {:noreply, push_navigate(socket, to: ~p"/student/spelling_review")}
  end

  defp build_full_grid(sparse_grid, grid_rows, grid_cols, placements) do
    # Create a flat list of all cells in row-major order
    for row <- 0..(grid_rows - 1),
        col <- 0..(grid_cols - 1) do
      
      letter = Map.get(sparse_grid, {row, col})
      
      # Find if this cell is the start of any word
      number = placements
        |> Enum.find(fn p -> p.row == row and p.col == col end)
        |> case do
          nil -> nil
          placement -> placement.number
        end
      
      %{
        row: row,
        col: col,
        letter: letter,
        number: number,
        filled: letter != nil
      }
    end
  end
end