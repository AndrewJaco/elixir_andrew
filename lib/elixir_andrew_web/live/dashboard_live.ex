defmodule ElixirAndrewWeb.DashboardLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_info({:theme_changed, theme}, socket) do
    {:noreply, assign(socket, :theme, theme)}
  end
end
