defmodule ElixirAndrewWeb.Component.ThemeSelector do
  use ElixirAndrewWeb, :live_component

  @doc """
  Renders a theme selector component.
  """
  def render(assigns) do
    ~H"""
    <div class="pt-1 pb-4 px-4" id="theme-selector" data-theme={@theme}>
      <form phx-change="change_theme" class="text-secondary">
        <label for="theme" class="block my-1 text-xs text-black">Colors</label>
        <select 
          id="theme" 
          name="theme" 
          phx-change="change_theme" 
          phx-target={@myself}
          class="p-2 w-full border border-primary rounded-md bg-none text-center appearance-none">
          <option value="theme-default" selected={@theme == "theme-default"}>T. Andrew</option>
          <option value="theme-mc" selected={@theme == "theme-mc"}>Minecraft</option>
          <option value="theme-hk" selected={@theme == "theme-hk"}>Hello Kitty</option>
          <option value="theme-lg" selected={@theme == "theme-lg"}>Lego</option>
        </select>
      </form>
    </div>
    """
  end

  def handle_event("change_theme", %{"theme" => theme}, socket) do
    send(self(), {:theme_changed, theme})
    {:noreply, 
      socket
      |> assign( theme: theme)
      |> push_event("store_theme", %{theme: theme})}
  end
end