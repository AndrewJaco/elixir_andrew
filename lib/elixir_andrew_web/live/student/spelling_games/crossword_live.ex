defmodule ElixirAndrewWeb.Student.SpellingGames.CrosswordLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Live.SpellingGames.CrosswordGenerator

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:student_id, session["student_id"])
      |> assign(:spelling_words, session["spelling_words"])
      |> assign(:game_state, :loading) # :loading, :in_progress, :completed
      |> assign(:error, nil)

    if connected?(socket) do
      {:ok, initialize_game(socket, session)}
    else
      {:ok, socket}
    end
  end
  
  def render(assigns) do
    ~H"""
    <div class="crossword-game">
      <h1>Crossword Puzzle</h1>
    </div>
    """
  end

  defp initialize_game(socket, _session) do
    user_id = socket.assigns.student_id

    with 
      {:ok, progress} <- ElixirAndrew.progress.get_user_progress!(user_id),
      {:ok, crossword} <- CrosswordGenerator.generate_crossword(socket.assigns.spelling_words, progress) do
        
        socket
        |> assign(:crossword, crossword)
        |> assign(:game_state, :in_progress)
    else
      {:error, reason} ->
        socket
        |> assign(:error, reason)
        |> assign(:game_state, :completed)
    end
  end


end