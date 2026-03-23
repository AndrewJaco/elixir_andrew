defmodule ElixirAndrewWeb.Student.SpellingGames.CrosswordLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.CrosswordGenerator
  alias ElixirAndrewWeb.Student.SpellingGames.Crossword.PlacedWord
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
    
    # Check if clues were pre-generated and passed via flash
    pregenerated_clues = case Map.get(session, "flash") do
      %{"crossword_clues" => encoded_clues} when is_binary(encoded_clues) ->
        case Jason.decode(encoded_clues) do
          {:ok, clues} -> clues
          _ -> nil
        end
      _ -> nil
    end
    
    socket =
      socket
      |> assign(:spelling_words, spelling_words)
      |> assign(:game_state, if(pregenerated_clues, do: :ready, else: :loading))
      |> assign(:error, nil)
      |> assign(:words_with_clues, pregenerated_clues)
      |> assign(:grid_state, nil)
      |> assign(:placed_word_list, [])
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
        
        <% :in_progress -> %>
          <div>
            <h2 class="text-xl font-semibold mb-4">Generated Clues (Test)</h2>
            <ul class="space-y-2">
              <%= for word <- @words_with_clues do %>
                <li class="border p-2 rounded">
                  <strong><%= word["word"] %>:</strong> <%= word["clue"] %>
                </li>
              <% end %>
            </ul>
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
        socket
        |> assign(:grid_state, grid_state.grid)
        |> process_placements(grid_state.placements)
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

  defp process_placements(socket, placements) do

    Enum.each(placements, fn placement ->
      Logger.info("Placed word '#{placement.word}' at #{placement.row},#{placement.col} (#{placement.direction})")
      
    end)

    socket
  end
end