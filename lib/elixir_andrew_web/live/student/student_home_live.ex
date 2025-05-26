defmodule ElixirAndrewWeb.Student.StudentHomeLive do
  use ElixirAndrewWeb, :live_view

  def mount do
    {:ok, assign(:page_title, "Student Home")}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto">
      <.header class="text-center">
        <p class="text-3xl"><%= @current_user.first_name %> <%= @current_user.last_name %></p>
        <p class="text-secondary">Welcome to your student home page! </p>
      </.header>

      <p class="text-center">
        Here you can find lessons and homework.
      </p>

      <div class="mt-6 flex justify-center">
        <.link href={~p"/"} class="text-accent hover:underline">
          View Lessons
        </.link>
        <span class="mx-2">|</span>
        <.link href={~p"/"} class="text-accent hover:underline">
          View Homework
        </.link>
      </div>
    </div>
    """
  end
 
end