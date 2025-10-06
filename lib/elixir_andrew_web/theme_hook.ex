defmodule ElixirAndrewWeb.ThemeHook do 
  import Phoenix.Component
  import Phoenix.LiveView
  alias ElixirAndrew.Accounts

  @debounce_delay 5000

  def on_mount(:default, _params, session, socket) do
    
    theme = cond do
      # Logged in user with theme set
      socket.assigns[:current_user] && socket.assigns[:current_user].theme ->
        socket.assigns.current_user.theme
      # Theme stored in session (for guests)
      session["theme"] ->
        session["theme"]
      
      true ->
        "theme-default"
    end

    socket = socket
    |> assign(:theme, theme)
    |> assign(:theme_save_timer, nil)
    |> attach_hook(:sync_theme_handler, :handle_event, fn
      "sync-theme", %{"theme" => theme}, socket ->
       if socket.assigns[:current_user] do
          # Logged-in users: ignore client theme
          {:halt, socket}
        else
          # Guests: store theme in session and update
          {:halt, assign(socket, :theme, theme)}
        end
      _, _, socket -> {:cont, socket}
    end)
     |> attach_hook(:theme_info_handler, :handle_info, fn
      {:theme_changed, theme}, socket -> handle_theme_info({:theme_changed, theme}, socket)
      {:persist_theme, theme}, socket -> handle_theme_info({:persist_theme, theme}, socket)
      _, socket -> {:cont, socket}
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

  defp handle_theme_info({:persist_theme, _theme}, socket) do
    socket = assign(socket, :theme_save_timer, nil)
    {:halt, socket}
  end

  #pass through other messages
  defp handle_theme_info(_other, socket), do: {:cont, socket}
end