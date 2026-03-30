defmodule ElixirAndrewWeb.Student.SpellingGames.CrosswordLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.CrosswordGenerator
  alias ElixirAndrewWeb.Student.SpellingGames.Crossword.{PlacedWord, ClueCache}
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
  def render(assigns) do
    ~H"""
    <div class="crossword-game p-8">
      <h1 class="text-3xl font-bold mb-4">Crossword Puzzle</h1>
      
      <%= case @game_state do %>
        <% :loading -> %>
          <div class="text-xl">Loading crossword puzzle...</div>
        <% :ready -> %>
          <div class="text-xl">Loading crossword puzzle...</div>
        <% :in_progress -> %>
          <div>
            <div class="flex justify-center pb-8">
              <%!-- grid --%>
              <div 
                class="crossword-grid inline-grid border-2 border-accent"
                style={"grid-template-columns: repeat(#{@grid_cols}, 40px); grid-template-rows: repeat(#{@grid_rows}, 40px);"}
              >
                <%= for cell <- @grid_state do %>
                  <div class={"relative w-10 h-10 border border-gray-400 flex items-center justify-center #{if cell.filled, do: "bg-white", else: "bg-black"}"}>
                    <%= if cell.number do %>
                      <span class="absolute top-0 left-0 text-xs p-0.5"><%= cell.number %></span>
                    <% end %>
                    <%= if cell.letter do %>
                      <span class="text-lg font-bold"><%= cell.letter %></span>
                    <% end %>
                  </div>
                <% end %>
              </div>

            </div>
            <div class="flex gap-8 border p-4 border-accent">
              <div>
                <h3 class="text-lg font-semibold mb-2">Across</h3>
                <ul class="border space-y-2">
                  <%= for word <- @placed_wordlist, word.direction == :across do %>
                    <li class="p-2">
                      <strong>#<%= word.number %>:</strong> <%= word.clue %>
                    </li>
                  <% end %>
                </ul>
              </div>

              <div>
                <h3 class="text-lg font-semibold mb-2">Down</h3>
                <ul class="border space-y-2">
                  <%= for word <- @placed_wordlist, word.direction == :down do %>
                    <li class="p-2">
                      <strong>#<%= word.number %>:</strong> <%= word.clue %>
                    </li>
                  <% end %>
                </ul>
              </div>
            </div>
          </div>
        
        <% :error -> %>
          <div class="text-red-600">
            <h2 class="text-xl font-semibold">Error</h2>
            <p>Failed to generate crossword: <%= inspect(@error) %></p>
          </div>
      <% end %>
    </div>
    """
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
        
        socket
        |> assign(:grid_state, full_grid)
        |> assign(:placed_wordlist, grid_state.placements)
        |> assign(:grid_rows, grid_state.grid_rows)
        |> assign(:grid_cols, grid_state.grid_cols)
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