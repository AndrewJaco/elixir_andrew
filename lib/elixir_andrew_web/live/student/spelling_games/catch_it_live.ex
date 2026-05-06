defmodule ElixirAndrewWeb.Student.SpellingGames.CatchItLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.Crossword.{ClueCache, CrosswordGenerator}
  require Logger

  @impl true
  def mount(params, _session, socket) do
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
      |> assign(:game_state, if(pregenerated_clues, do: :in_round, else: :loading))
      |> assign(:error, nil)
      |> assign(:words_with_clues, pregenerated_clues)
      |> assign(:current_word, nil)
      |> assign(:current_word_index, 0)
      |> assign(:words_to_drop, [])
      |> assign(:score, 0)
      |> assign(:current_bonus, 10)
      |> assign(:initialized, false)

      if connected?(socket) and not socket.assigns.initialized do
        if pregenerated_clues do
          send(self(), :start_first_round)
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
    <div class="catch-it-game">
      <h1>Catch It</h1>
       
      <%= if @game_state == :loading do %>
        <p>Loading game...</p>
      <% end %>
      <%= if @game_state == :error do %>
        <p class="error">Error: <%= @error %></p>
      <% end %>
      <%= if @game_state == :in_round do %>
        <p>Current Score: <%= @score %></p>
        <p>Current Bonus: <%= @current_bonus %></p>
        <p>Current Word: <%= @current_word.word %></p>
        <p>Clue: <%= @current_word.clue %></p>
        <div class="words-to-drop flex space-x-4 mt-4">
          <%= for word <- @words_to_drop do %>
            <button class="drop-word" phx-click="word_caught" phx-value-id={word.id}><%= word.word %></button>
          <% end %>
        </div>
      <% end %>
      <%= if @game_state == :game_over do %>
        <p>Game Over! Final Score: <%= @score %></p>
        <button phx-click="play_again">Play Again</button>
      <% end %>
    </div>

    """
  end

   @impl true
  def handle_info(:initialize_game, socket) do
    Logger.info("Initializing catch it game (generating clues)...")
    
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
              Logger.info("✓ Clues generated, now starting first round...")
              send(self(), :start_first_round)
              assign(socket, words_with_clues: clues, game_state: :loading, initialized: true)
            
            {:error, reason} ->
              Logger.error("✗ Failed to generate clues: #{inspect(reason)}")
              assign(socket, game_state: :error, error: reason, initialized: true)
          end
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:start_first_round, socket) do
    Logger.info("Starting first round of Catch It...")
    indexed_words =
      socket.assigns.words_with_clues
      |> List.wrap()
      |> Enum.shuffle()
      |> Enum.with_index(fn word_with_clue, index ->
        word_with_clue
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
        |> Map.put(:id, index)
      end)

    current_word = List.first(indexed_words)
    remaining_words = Enum.reject(indexed_words, &(&1.id == current_word.id))
    distractors = Enum.take(remaining_words, 3)

    words_to_drop =
      [current_word | distractors]
      |> Enum.reject(&is_nil/1)
      |> Enum.shuffle()

    {:noreply,
     assign(socket,
       words_with_clues: indexed_words,
       current_word: current_word,
       words_to_drop: words_to_drop,
       current_word_index: 0,
       game_state: :in_round
     )}
  end

  
  @impl true
  def handle_info(:next_round, socket) do
    current_index = socket.assigns.current_word_index + 1
    words_with_clues = socket.assigns.words_with_clues
    
    if current_index < length(words_with_clues) do
      next_current_word = Enum.at(words_with_clues, current_index)
      remaining_words = Enum.reject(words_with_clues, &(&1.id == next_current_word.id))
      distractors = remaining_words
      |> Enum.shuffle()
      |> Enum.take(3)
      
      words_to_drop =
      [next_current_word | distractors]
      |> Enum.reject(&is_nil/1)
      
      {:noreply,
      assign(socket,
      current_word: next_current_word,
      words_to_drop: words_to_drop,
      current_word_index: current_index,
      current_bonus: 10
      )}
    else
      Logger.info("No more words left. Game over.")
      {:noreply, assign(socket, game_state: :game_over)}
    end
  end
  
  @impl true
  def handle_event("word_caught", %{"id" => word_id}, socket) do
    word_id = String.to_integer(word_id)
    Logger.info("Word caught with ID: #{word_id}")
    current_word = socket.assigns.current_word

    if current_word && current_word.id == word_id do
      Logger.info("Correct word caught! Incrementing score.")
      socket = update(socket, :score, &(&1 + socket.assigns.current_bonus))
      send(self(), :next_round)
      {:noreply, socket}
    else
      Logger.info("Incorrect word caught. Bonus decreased.")
      {:noreply, update(socket, :current_bonus, &(&1 - 2))}
    end
  end
end