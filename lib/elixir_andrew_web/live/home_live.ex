defmodule ElixirAndrewWeb.HomeLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrew.Accounts

  def mount(_params, session, socket) do
    current_user = 
      case Map.get(session, "user_token") do
        nil -> nil
        user_token -> Accounts.get_user_by_session_token(user_token)
      end
    
    {:ok, assign(socket, current_user: current_user)}
  end
  
  def render(assigns) do
    ~H"""
    <.header class="text-center">
      <%= if @current_user do %>
        <div class="flex flex-col items-center">
          <h2>Welcome back, <%= @current_user.first_name %>!</h2>
          <.link navigate={~p"/dashboard"} class="btn">Go to Dashboard</.link>
          <.link 
            href={~p"/users/log_out"}
            method="delete"
            class="btn">
            Log Out
          </.link>
        </div>
      <% else %>
        <div class="flex flex-col items-center">
        <h2>Welcome</h2>

          <.link navigate={~p"/users/log_in"} class="btn">Log In</.link>
          <.link navigate={~p"/"} class="btn">Continue as Guest</.link>
        </div>
      <% end %>
    </.header>
    """
  end
end