defmodule ElixirAndrewWeb.Student.CommunicationComponent do
  use ElixirAndrewWeb, :live_component

  @doc """
  Renders a single class session component.
  """
  def render(assigns) do
    ~H"""
    <div class="p-4 border-rounded-xl border-secondary w-full bg-white shadow-md flex">
      <h2><%= @session.date %></h2>
      <div class="ml-4">
        <p class="">Lesson: <%= @session.lesson %></p>
        <p>Homework: <%= @session.homework %></p>
        <p>Spelling Words: <%= Enum.join(@session.spelling_words, ", ") %></p>
      </div>
    </div>
    """
  end
end