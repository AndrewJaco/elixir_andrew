defmodule ElixirAndrewWeb.HomeLive do
  use ElixirAndrewWeb, :live_view
  import ElixirAndrewWeb.BoxComponents

  def mount(_params, _session, socket) do
    theme = case Map.get(socket.assigns, :current_user) do
        nil -> "theme-default"
        user -> user.theme || "theme-default"
      end
    
    socket = assign(socket, theme: theme)
    {:ok, socket}
  end

  def handle_info({:theme_changed, theme}, socket) do
    {:noreply, assign(socket, theme: theme)}
  end
end