defmodule ElixirAndrewWeb.Student.SpellingGames.UnscrambleLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
   student_id = socket.assigns.current_user.id

    socket = 
      socket
      |> assign(:student_id, student_id)
      |> initialize_game()
    
    {:ok, socket}
  end

  defp initialize_game(socket) do
    spelling_words = Enum.shuffle(socket.assigns.spelling_words)
    initial_scramble = scramble_word(hd(spelling_words))

    socket 
    |> assign(:spelling_words, spelling_words)
    |> assign(:current_word, hd(spelling_words))
    |> assign(:scrambled_word, initial_scramble)
    |> assign(:original_scrambled_letters, initial_scramble)
    |> assign(:max_attempts, 2)
    |> assign(:attempts, 0)
    |> assign(:container_id, 0)
    |> assign(:game_state, :intro) # :intro, :in_round, :round_success, :round_fail, :game_over
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col flex-1 items-center justify-center">
      <%= if @game_state == :intro do %>
      <h1>Unscramble the spelling words!</h1>
      <button phx-click="start_game" class="btn-primary btn-effect mt-4">Start Game</button>
      <% end %>

      <%= if @game_state == :in_round || @game_state == :round_success || @game_state == :round_fail do %>
        <div class="flex flex-col items-center justify-center">
          <%= if @game_state == :round_success do %>
            <div class="text-center text-green-600 font-bold text-2xl mt-4 absolute top-16 left-0 right-0">
              <p class="">Congratulations!</p>
            </div>
          <% end %>
          <div 
            class="flex gap-4 mb-16" 
            phx-hook="Sortable" 
            id={"scramble-container-#{@container_id}"} 
            phx-update="ignore">
            <%= for {letter, index} <- Enum.with_index(@scrambled_word) do %>
              <div id={"letter-#{index}"} data-id={"letter-#{index}"} class="letter-block"><%= letter %></div>
            <% end %>
          </div>
          <div class="">
            <%= if @game_state == :in_round do %>
            <button 
              phx-click="guess_word" class="btn-primary btn-effect mr-4"
            >Guess
            </button>
            <% end %>
            <%= if @game_state == :round_fail do %>
            <button
              phx-click="restart_round" class="btn-primary btn-effect mr-4"
            >Try Again
            </button>
            <% end %>
            <%= if @game_state == :round_success do %>
            <button
              phx-click="start_next_word" class="btn-primary btn-effect mr-4"
            >Next Word
            </button>
            <% end %>
            
            <% remaining = @max_attempts - @attempts %>
            <% lost = @attempts %>
            <% heartbeat_class = cond do
              remaining == @max_attempts -> ""
              remaining <= 1 -> "dying-heart"
              true -> ""
            end %>

            <%= if remaining > 0 do %>
              <%= for _i <- 1..remaining do %>
                <.icon name="hero-heart" class={"h-12 w-12 mr-2 text-red-500 #{heartbeat_class}"}/>
              <% end %>
            <% end %>
            
            <%= if lost > 0 do %>
              <%= for _j <- 1..lost do %>
                <.icon name="hero-heart" class="h-12 w-12 mr-2 text-gray-400"/>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @game_state == :game_over do %>
        <div class="text-center">
          <h1 class="text-2xl font-bold mb-4">You've completed all the words!</h1>
          <button phx-click="end_game"  class="btn-primary btn-effect">Back</button>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("start_game", _params, socket) do
    {:noreply, assign(socket, game_state: :in_round)}
  end

  def handle_event("start_next_word", _params, socket) do
    advance_to_next_word(socket)
  end

  def handle_event("guess_word", _params, socket) do
    guessed_word = Enum.join(socket.assigns.scrambled_word, "")
    
    IO.inspect(guessed_word, label: "Guessed word")
    IO.inspect(socket.assigns.current_word, label: "Current word")
    
    cond do
      String.downcase(guessed_word) == String.downcase(socket.assigns.current_word) ->
        {:noreply, assign(socket, game_state: :round_success)}
      
      socket.assigns.attempts + 1 >= socket.assigns.max_attempts ->
        {:noreply, assign(socket, game_state: :round_fail, attempts: socket.assigns.max_attempts)}
      
      true ->
        {:noreply, assign(socket, attempts: socket.assigns.attempts + 1)}
    end
  end

  def handle_event("restart_round", _params, socket) do    
    scrambled = scramble_word(socket.assigns.current_word)
    {:noreply, assign(socket, 
      game_state: :in_round, 
      scrambled_word: scrambled,
      original_scrambled_letters: scrambled,
      attempts: 0,
      container_id: socket.assigns.container_id + 1
    )}
  end

  def handle_event("reorder", %{"ids" => ids}, socket) do
    reordered_letters = 
      ids
      |> Enum.map(fn id -> String.replace_prefix(id, "letter-", "") end)
      |> Enum.map(&String.to_integer/1)
      |> Enum.map(fn index -> Enum.at(socket.assigns.original_scrambled_letters, index) end)

    {:noreply, assign(socket, scrambled_word: reordered_letters)}
  end

  def handle_event("end_game", _params, socket) do
    # database call to record game completion and game history will go here
    
    {:noreply, push_navigate(socket, to: ~p"/student/home")}
  end

  defp scramble_word(word) do
    word
    |> String.graphemes()
    |> Enum.shuffle()
  end

  defp advance_to_next_word(socket) do
    remaining_words = tl(socket.assigns.spelling_words)

    if remaining_words == [] do
      {:noreply, assign(socket, game_state: :game_over)}
    else
      next_word = hd(remaining_words)
      scrambled_word = scramble_word(next_word)

      socket = 
        socket
        |> assign(:spelling_words, remaining_words)
        |> assign(:current_word, next_word)
        |> assign(:scrambled_word, scrambled_word)
        |> assign(:original_scrambled_letters, scrambled_word)
        |> assign(:attempts, 0)
        |> assign(:container_id, socket.assigns.container_id + 1)
        |> assign(:game_state, :in_round)

      {:noreply, socket}
    end
  end
  
end