defmodule ElixirAndrewWeb.Student.SpellingGames.FlashcardsLive do
  use ElixirAndrewWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flashcards-game">
      <h1>Flashcards</h1>
    </div>
    """
  end
end