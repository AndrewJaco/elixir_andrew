defmodule ElixirAndrewWeb.Student.SpellingGames.FlashcardsLive do
  use ElixirAndrewWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "Flashcards")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flashcards-game">
      <h1><%= @name %></h1>
    </div>
    """
  end
end