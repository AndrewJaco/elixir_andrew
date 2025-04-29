defmodule ElixirAndrewWeb.Component.ThemeSelector do
  use ElixirAndrewWeb, :live_component

  @doc """
  Renders a theme selector component.
  """
  def render(assigns) do
    ~H"""
    <div class="p-4">
    <pre class="text-xs text-gray-500">Theme: <%= inspect(@theme) %></pre>
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
          <option value="theme-hk" disabled selected={@theme == "theme-hk"}>Hello Kitty</option>
          <option value="theme-lg" disabled selected={@theme == "theme-lg"}>Lego</option>
        </select>
      </form>
    </div>
    """
  end

  def handle_event("change_theme", %{"theme" => theme}, socket) do
    # Here you would typically save the theme preference to the database
    # For now, we just assign it to the socket
    send(self(), {:theme_changed, theme})
    {:noreply, assign(socket, theme: theme)}
  end
end