defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearchLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "Word Search")}
  end

  def render(assigns) do
    ~H"""
    <div class="word-search-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end