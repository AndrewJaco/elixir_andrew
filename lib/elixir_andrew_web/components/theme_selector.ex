defmodule ElixirAndrewWeb.Component.ThemeSelector do
  use ElixirAndrewWeb, :live_component

  @doc """
  Renders a theme selector component.
  """
  def render(assigns) do
    ~H"""
    <div class="p-4" id="theme-selector" phx-hook="ThemeHandler" data-theme={@theme}>
      <form phx-change="change_theme" class="text-secondary mb-4">
        <label for="theme" class="block mb-2 font-semibold">Choose a Theme:</label>
        <select 
          id="theme" 
          name="theme" 
          phx-change="change_theme" 
          phx-target={@myself}
          class="p-2 border rounded">
          <option value="" selected={@theme == ""}>Teacher Andrew</option>
          <option value="theme-mc" selected={@theme == "theme-mc"}>Minecraft</option>
          <option value="theme-hk" selected={@theme == "theme-hk"}>Hello Kitty</option>
          <option value="theme-lg" selected={@theme == "theme-lg"}>Lego</option>
        </select>
      </form>
    </div>
    """
  end

  def handle_event("change_theme", %{"theme" => theme}, socket) do
    # Here you would typically save the theme preference to the database
    # For now, we just assign it to the socket
    send(self(), {:theme_changed, theme})
    {:noreply, 
      socket
      |> assign( theme: theme)
      |> push_event("store_theme", %{theme: theme})}
  end
end