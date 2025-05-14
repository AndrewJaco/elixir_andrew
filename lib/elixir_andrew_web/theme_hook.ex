defmodule ElixirAndrewWeb.ThemeHook do 
  import Phoenix.Component
  import Phoenix.LiveView
  # alias ElixirAndrew.Accounts

  def on_mount(:default, _params, session, socket) do
    
    theme = session["theme"] || ""

    socket = socket
    |> assign(:theme, theme)
    |> attach_hook(:handle_theme_changes, :handle_info, &handle_theme_info/2)

    socket = attach_hook(socket, :sync_theme_from_js, :handle_event, fn
       "sync-theme", %{"theme" => theme}, socket ->
        socket = assign(socket, :theme, theme)

         {:halt, socket}
         _, _, socket ->
         {:cont, socket}
    end)

    {:cont, socket}
  end

  defp handle_theme_info({:theme_changed, theme}, socket) do
    socket = socket
    |> assign(:theme, theme)
    |> push_event("store_theme", %{theme: theme})

    # Here you would typically save the theme preference to the database
    {:halt, socket}
  end

  #pass through other messages
  defp handle_theme_info(_other, socket), do: {:cont, socket}
end