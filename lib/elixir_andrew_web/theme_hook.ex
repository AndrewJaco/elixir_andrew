defmodule ElixirAndrewWeb.ThemeHook do 
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 2]
  alias ElixirAndrew.Accounts

  def on_mount(:set_theme, _params, _session, socket) do
    # Get theme from user if authenticated, otherwise set to default
    theme = case socket.assigns do
      %{current_user: %{theme: user_theme}} when not is_nil(user_theme) -> user_theme
        _ ->
          # Default theme for guests or users without a theme set
          ""
    end

    {:cont, assign(socket, theme: theme)}
  end
end