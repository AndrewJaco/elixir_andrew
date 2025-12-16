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

    socket 
    |> assign(:spelling_words, spelling_words)
    |> assign(:current_word, hd(spelling_words))
    |> assign(:scrambled_word, scramble_word(hd(spelling_words)))
    |> assign(:guessed_word, [])
    |> assign(:max_attempts, 2)
    |> assign(:attempts, 0)
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
          <div class="flex gap-4 mb-16" phx-hook="Sortable" id="scramble-container" phx-update="ignore">
            <%= for {letter, index} <- Enum.with_index(@scrambled_word) do %>
              <div id={"letter-#{index}"} data-id={"letter-#{index}"} class="letter-block"><%= letter %></div>
            <% end %>
          </div>
          <div class="">
            <button phx-click="guess_word" class="btn-primary btn-effect mr-4">Guess</button>
            
            
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
    </div>
    """
  end

  def handle_event("start_game", _params, socket) do
    {:noreply, assign(socket, game_state: :in_round)}
  end

  def handle_event("start_next_word", _params, socket) do
    advance_to_next_word(socket)
  end

  def handle_event("guess_word", %{"word" => guessed_word}, socket) do
    IO.inspect(guessed_word, label: "Guessed word")
    
    if String.downcase(guessed_word) == String.downcase(socket.assigns.current_word) do
      {:noreply, assign(socket, game_state: :round_success)}
    else
      {:noreply, assign(socket, attempts: socket.assigns.attempts + 1)}
    end
  end

  def handle_event("reorder", %{"ids" => ids}, socket) do

    reordered_letters = 
      ids
      |> Enum.map(fn id -> String.replace_prefix(id, "letter-", "") end)
      |> Enum.map(&String.to_integer/1)
      |> Enum.map(fn index -> Enum.at(socket.assigns.scrambled_word, index) end)

    {:noreply, assign(socket, scrambled_word: reordered_letters)}
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
        |> assign(:guessed_word, [])
        |> assign(:game_state, :in_round)

      {:noreply, socket}
    end
  end
  
end