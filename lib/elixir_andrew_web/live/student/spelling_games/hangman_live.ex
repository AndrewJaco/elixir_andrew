defmodule ElixirAndrewWeb.Student.SpellingGames.HangmanLive do
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
    spelling_words = socket.assigns.spelling_words
    |> Enum.shuffle()

    IO.inspect(spelling_words, label: "Hangman shuffled spelling words")

    # create a list of all letters of the alphabet
    alphabet = Enum.to_list(?a..?z) |> Enum.map(&<<&1>>)

    socket 
    |> assign(:name, "Hangman")
    |> assign(:spelling_words, spelling_words)
    |> assign(:correct_guesses, [])
    |> assign(:incorrect_guesses, [])
    |> assign(:max_incorrect_guesses, 6)
    |> assign(:current_word, nil)
    |> assign(:game_over, false)
  end

  def render(assigns) do
    ~H"""
    <div class="hangman-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end