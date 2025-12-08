defmodule ElixirAndrewWeb.Student.SpellingGames.UnscrambleLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "Unscramble")}
  end

  def render(assigns) do
    ~H"""
    <div class="unscramble-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end