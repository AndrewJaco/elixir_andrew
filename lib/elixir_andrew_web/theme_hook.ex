defmodule ElixirAndrewWeb.ThemeHook do 
  import Phoenix.Component
  import Phoenix.LiveView
  alias ElixirAndrew.Accounts

  @debounce_delay 5000

  def on_mount(:default, _params, session, socket) do
    
    theme = session["theme"] || "theme-default"

    socket = socket
    |> assign(:theme, theme)
    |> assign(:theme_save_timer, nil)
    |> attach_hook(:handle_theme_changes, :handle_info, &handle_theme_info/2)
    |> attach_hook(:sync_theme_from_js, :handle_event, fn
      "sync-theme", %{"theme" => theme}, socket ->
        socket = assign(socket, :theme, theme)
        {:halt, socket}
      _, _, socket ->
        {:cont, socket}
    end)

    {:cont, socket}
  end

  defp handle_theme_info({:theme_changed, theme}, socket) do
    socket = assign(socket, :theme, theme)

    if socket.assigns[:theme_save_timer] do
      Process.cancel_timer(socket.assigns[:theme_save_timer])
    end

    # Set a timer to save the theme preference after a delay
    timer_ref = Process.send_after(self(), {:persist_theme, theme}, @debounce_delay)

    socket =
      socket
      |> assign(:theme_save_timer, timer_ref)
      |> push_event("store_theme", %{theme: theme})

    {:halt, socket}
  end

  defp handle_theme_info({:persist_theme, theme}, %{assigns: %{current_user: %{id: user_id}}} = socket) do
    _ = Accounts.update_user_theme(user_id, theme)

    # Clear timer after saving
    socket = assign(socket, :theme_save_timer, nil)
    {:halt, socket}
  end

  #pass through other messages
  defp handle_theme_info(_other, socket), do: {:cont, socket}
end