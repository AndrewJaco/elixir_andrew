defmodule ElixirAndrewWeb.DashboardLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_info({:theme_changed, theme}, socket) do
    # Handle the theme change event here
    # For example, you might want to store the theme in the session or database
    {:noreply, assign(socket, theme: theme)}
  end
end
