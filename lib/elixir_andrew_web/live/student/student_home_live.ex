defmodule ElixirAndrewWeb.Student.StudentHomeLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, session, socket) do
    current_user = 
    case Map.get(session, "user_token") do
      nil -> nil
      user_token -> ElixirAndrew.Accounts.get_user_by_session_token(user_token)
    end
    if current_user == nil do
      {:ok, redirect(socket, to: ~p"/login")}
    else
      theme = current_user.theme || "theme-default"
      socket = assign(socket, current_user: current_user, theme: theme, student_id: current_user.id)
      {:ok, socket}
    end    
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto">
      <.header class="text-center">
        <p class="text-3xl"><%= @current_user.first_name %> <%= @current_user.last_name %> </p>
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
        <.link href={~p"/student/#{@student_id}/communication"} class="text-accent hover:underline">
          View Homework
        </.link>
      </div>
    </div>
    """
  end
 
end