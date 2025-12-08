defmodule ElixirAndrewWeb.Student.SpellingGames.CatchItLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "Catch It")}
  end

  def render(assigns) do
    ~H"""
    <div class="catch-it-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end