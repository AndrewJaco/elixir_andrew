defmodule ElixirAndrewWeb.Student.SpellingGames.MatchingLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "Matching")}
  end

  def render(assigns) do
    ~H"""
    <div class="matching-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end 