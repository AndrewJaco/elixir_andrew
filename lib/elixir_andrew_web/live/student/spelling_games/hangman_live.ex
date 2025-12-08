defmodule ElixirAndrewWeb.Student.SpellingGames.HangmanLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "Hangman")}
  end

  def render(assigns) do
    ~H"""
    <div class="hangman-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end