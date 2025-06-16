defmodule ElixirAndrewWeb.HomeLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrew.Accounts

  def mount(_params, session, socket) do
    current_user = 
      case Map.get(session, "user_token") do
        nil -> nil
        user_token -> Accounts.get_user_by_session_token(user_token)
      end

      theme = 
        case current_user do
          nil -> "theme-default"
          user -> user.theme || "theme-default"
        end
    
    {:ok, assign(socket, current_user: current_user, theme: theme)}
  end

  def handle_info({:theme_changed, theme}, socket) do
    {:noreply, assign(socket, theme: theme)}
  end
end