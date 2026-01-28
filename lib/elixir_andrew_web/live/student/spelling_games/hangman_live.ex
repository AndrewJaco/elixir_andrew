defmodule ElixirAndrewWeb.Student.SpellingGames.HangmanLive do
  use ElixirAndrewWeb, :live_view

  def mount(params, _session, socket) do
    student_id = socket.assigns.current_user.id

    spelling_words = case params["spelling_words"] do
      nil -> []
      words when is_binary(words) -> 
        words
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
      words when is_list(words) -> words
    end

    socket = 
      socket
      |> assign(:student_id, student_id)
      |> assign(:spelling_words, spelling_words)
      |> initialize_game()
    
    {:ok, socket}
  end

  defp initialize_game(socket) do
    spelling_words = Enum.shuffle(socket.assigns.spelling_words)

    socket 
    |> assign(:spelling_words, spelling_words)
    |> assign(:guessed_letters, MapSet.new())
    |> assign(:correct_letters, MapSet.new())
    |> assign(:incorrect_letters, MapSet.new())
    |> assign(:max_incorrect_guesses, 6)
    |> assign(:current_word, hd(spelling_words))
    |> assign(:game_state, :intro) # :intro, :in_round, :round_success, :round_fail, :game_over
  end

  def handle_event("guess_letter", %{"letter" => letter}, socket) do
    IO.inspect(letter, label: "Guessed letter")
    
    letter = String.downcase(letter)

    socket = 
      if MapSet.member?(socket.assigns.guessed_letters, letter) do
        socket
      else
        current_word = String.downcase(socket.assigns.current_word)
        guessed_letters = MapSet.put(socket.assigns.guessed_letters, letter)

        if String.contains?(current_word, letter) do
          correct_letters = MapSet.put(socket.assigns.correct_letters, letter)
          assign(socket, guessed_letters: guessed_letters, correct_letters: correct_letters)
        else
          incorrect_letters = MapSet.put(socket.assigns.incorrect_letters, letter)
          assign(socket, guessed_letters: guessed_letters, incorrect_letters: incorrect_letters)
        end
      end
    
    check_round_over(socket)
  end

  def handle_event("start_game", _params, socket) do
    {:noreply, assign(socket, game_state: :in_round)}
  end

  def handle_event("start_next_word", _params, socket) do
    advance_to_next_word(socket)
  end

  defp check_round_over(socket) do
    current_word = String.downcase(socket.assigns.current_word)
    # Get letters only (exclude spaces and non-letter characters)
    current_word_letters = 
      current_word 
      |> String.graphemes() 
      |> Enum.reject(&(&1 == " "))
      |> MapSet.new()
    
    if MapSet.subset?(current_word_letters, socket.assigns.correct_letters) do
      # Word guessed correctly
      Process.send_after(self(), :start_next_word, 2000)
      {:noreply, assign(socket, game_state: :round_success)}
    else
      if MapSet.size(socket.assigns.incorrect_letters) >= socket.assigns.max_incorrect_guesses do
        # Too many incorrect guesses - add word back to end of list
        updated_words = socket.assigns.spelling_words ++ [socket.assigns.current_word]
        # Process.send_after(self(), :start_next_word, 5000)
        {:noreply, assign(socket, game_state: :round_fail, spelling_words: updated_words)}
      else
        {:noreply, socket}
      end
    end
  end

  def handle_info(:start_next_word, socket) do
    advance_to_next_word(socket)
  end

  defp advance_to_next_word(socket) do
    remaining_words = tl(socket.assigns.spelling_words)

    if remaining_words == [] do
      {:noreply, assign(socket, game_state: :game_over, current_word: nil, incorrect_letters: MapSet.new(), correct_letters: MapSet.new(), guessed_letters: MapSet.new())}
    else
      next_word = hd(remaining_words)
      {:noreply, 
        socket
        |> assign(:current_word, next_word)
        |> assign(:spelling_words, remaining_words)
        |> assign(:guessed_letters, MapSet.new())
        |> assign(:correct_letters, MapSet.new())
        |> assign(:incorrect_letters, MapSet.new())
        |> assign(:game_state, :in_round)
      }
    end
  end
  
end