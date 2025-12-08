defmodule ElixirAndrewWeb.Student.SpellingGames.CrosswordLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "Crossword")}
  end

  def render(assigns) do
    ~H"""
    <div class="crossword-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end