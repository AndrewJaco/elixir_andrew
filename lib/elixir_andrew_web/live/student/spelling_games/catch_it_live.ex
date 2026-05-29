defmodule ElixirAndrewWeb.Student.SpellingGames.CatchItLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.Crossword.ClueCache
  alias ElixirAndrewWeb.Student.SpellingGames.ClueGenerator
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
      |> assign(:game_state, if(pregenerated_clues, do: :intro, else: :loading))
      |> assign(:error, nil)
      |> assign(:words_with_clues, pregenerated_clues)
      |> assign(:current_word, nil)
      |> assign(:current_word_index, 0)
      |> assign(:words_to_drop, [])
      |> assign(:score, 0)
      |> assign(:current_bonus, 10)
      |> assign(:feedback_state, nil)
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
    <div class="catch-it-game flex flex-1 px-4">
      <%= if @game_state == :loading do %>
        <p>Loading game...</p>
      <% end %>
      <%= if @game_state == :error do %>
        <p class="error">Error: <%= @error %></p>
      <% end %>
      <%= if @game_state in [:intro, :in_round, :game_over] do %>
        <div id="catch-it-container"
            class="flex flex-col flex-1 w-full border-2 border-gray-300 rounded-lg overflow-hidden bg-blue-50"
        >
          <div id="catch_it_topbar" class="flex-shrink-0 w-full bg-white p-2 border-b-2 border-gray-300 flex justify-center gap-4 items-center">
            <div class={"scoreboard border-2 border-primary rounded-lg m-2 px-4 py-2 h-24 w-48 flex flex-col justify-center items-center #{
              case @feedback_state do
                :correct -> "animate-feedback-correct"
                :incorrect -> "animate-feedback-incorrect"
                _ -> ""
              end
            }"}> 
              <p class="text-lg">Score: <%= @score %></p>
              <p class="text-lg">Bonus: <%= @current_bonus %></p>
            </div>
            <div class="m-2 px-4 py-2 w-1/3 h-24 flex flex-col justify-center items-center">
              <%= if @game_state !== :game_over do %>
                <p><%= @current_word_index + 1 %> / <%= length(@words_with_clues) %></p>
              <% end %>
              <%= if @current_word do %>
                <p class="text-lg">Clue: <%= @current_word.clue %></p>
              <% end %>
            </div>
          </div>
          <div id="words-layer"
            phx-hook="CatchIt"
            data-current-word={if @current_word, do: @current_word.id, else: ""}
            data-running={to_string(@game_state in [:intro, :in_round])}
            class="relative flex-1 w-full bg-[url('/images/wavy1.svg')] bg-cover bg-no-repeat bg-center overflow-hidden"
          >
          
            <%= for word <- @words_to_drop do %>
              <div 
                id={"word-#{word.id}"} 
                class="falling-word absolute text-lg bg-white px-8 py-4 border-1 border-primary rounded shadow" 
                data-id={word.id}
              >
                <%= word.word %>
              </div>
            <% end %>
            <div
              id="ground" 
              class="absolute bottom-0 w-full h-[130px] flex justify-center ground-gradient"
              >
              <div
                id="bucket"
                class="self-center w-40 h-24 bg-gray-800 rounded-xl flex items-center justify-center text-white text-lg"
                >
                Catch Here
              </div>
            </div>
          </div>
        </div>
      <% end %>
      <%= if @game_state == :intro do %>  
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div class="wordsearch-modal px-8 py-10 border-2 border-primary rounded-lg text-center game-shadow flex flex-col items-center justify-center text-center overflow-auto">
            <h1 class="text-3xl font-bold mb-4">How to Play</h1>
            <p class="mb-6">Read the clue at the top and catch the correct fish!</p>
            <button phx-click="clear_intro" class="btn btn-primary">Ok!</button>
          </div>
        </div>
      <% end %>
      <%= if @game_state == :game_over do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div class="wordsearch-modal p-8 border-2 border-alert rounded-lg text-center game-shadow w-[70%] h-[70%] flex flex-col items-center justify-center text-center overflow-auto">
            <h1 class="text-3xl font-bold mb-4">Congratulations!</h1>
            <p class="mb-6">You caught all the words!</p>
            <p class="mb-6 text-xl font-bold text-accent"><%= @score %> Points!</p>
            <div class="flex gap-4"> 
              <button phx-click="restart_game" class="btn btn-primary">Play Again</button>
              <.link navigate={~p"/student/home"} class="btn btn-alert ml-4">Exit</.link>
            </div>
          </div>
        </div>
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
      case ClueGenerator.generate_clues(spelling_words, user_id, :catch_it) do
        {:ok, words_with_clues} ->
          Logger.info("✓ Clues generated, now starting first round...")
          send(self(), :start_first_round)
          assign(socket, words_with_clues: words_with_clues, game_state: :loading, initialized: true)
        
        {:error, reason} ->
          Logger.error("✗ Failed to generate clues: #{inspect(reason)}")
          assign(socket, game_state: :error, error: reason, initialized: true)
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
       game_state: :intro
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
      |> Enum.shuffle()
      
      {:noreply,
      assign(socket,
      current_word: next_current_word,
      words_to_drop: words_to_drop,
      current_word_index: current_index,
      current_bonus: 10
      )}
    else
      Logger.info("No more words left. Game over.")
      {:noreply, assign(socket, 
        game_state: :game_over,
        current_word: nil,
        words_to_drop: [],
        current_word_index: 0,
        current_bonus: 0
        )}
    end
  end
  
  @impl true
  def handle_event("clear_intro", _params, socket) do
    {:noreply, assign(socket, :game_state, :in_round)}
  end

  @impl true
  def handle_event("word_caught", %{"id" => word_id}, socket) do
    word_id = String.to_integer(word_id)
    Logger.info("Word caught with ID: #{word_id}")
    current_word = socket.assigns.current_word

    if current_word && current_word.id == word_id do
      Logger.info("Correct word caught! Incrementing score.")
      socket = update(socket, :score, &(&1 + socket.assigns.current_bonus))
        |> assign(:feedback_state, :correct)
      
      Process.send_after(self(), :clear_feedback, 600)
      send(self(), :next_round)
      {:noreply, socket}
    else
      Logger.info("Incorrect word caught. Bonus decreased.")
      socket = assign(socket, :feedback_state, :incorrect)
      
      socket =
        if socket.assigns.current_bonus > 0 do
          update(socket, :current_bonus, fn bonus -> max(bonus - 2, 0) end)
        else
          socket
        end

      Process.send_after(self(), :clear_feedback, 600)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("restart_game", _params, socket) do
    socket = assign(socket, score: 0, current_bonus: 10)
    send(self(), :initialize_game)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:clear_feedback, socket) do
    {:noreply, assign(socket, :feedback_state, nil)}
  end
end