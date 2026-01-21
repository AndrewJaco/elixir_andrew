defmodule ElixirAndrewWeb.Student.SpellingGames.MatchingLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end


  def render(assigns) do
    ~H"""
    <div class="matching-game">
      <h1>The Matching Game</h1>
    </div>
    """
  end
end 