defmodule ElixirAndrewWeb.Student.SpellingGames.CrosswordLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Live.SpellingGames.CrosswordGenerator
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :initialize_game)
    end
    
    socket =
      socket
      |> assign(:game_state, :loading)
      |> assign(:error, nil)
      |> assign(:words_with_clues, nil)

    {:ok, socket}
  end
  
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

  def handle_info(:initialize_game, socket) do
    Logger.info("Initializing crossword game...")
    
    spelling_words = socket.assigns.spelling_words
    user_id = socket.assigns.current_user.id
    
    case ElixirAndrew.Progress.get_user_progress(user_id) do
      nil ->
        Logger.error("No progress found for user #{user_id}")
        {:noreply, assign(socket, game_state: :error, error: "No progress found")}
      
      progress ->
        case CrosswordGenerator.generate_crossword(spelling_words, progress) do
          {:ok, words_with_clues} ->
            Logger.info("✓ Crossword generated successfully!")
            {:noreply, 
              socket
              |> assign(:words_with_clues, words_with_clues)
              |> assign(:game_state, :in_progress)
            }
          
          {:error, reason} ->
            Logger.error("✗ Failed to generate crossword: #{inspect(reason)}")
            {:noreply, assign(socket, game_state: :error, error: reason)}
        end
    end
  end
end