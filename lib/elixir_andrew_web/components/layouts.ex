defmodule ElixirAndrewWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use ElixirAndrewWeb, :controller` and
  `use ElixirAndrewWeb, :live_view`.
  """
  use ElixirAndrewWeb, :html
  alias Phoenix.LiveView.JS

  attr :theme, :string, required: true, doc: "the current theme"
  attr :current_user, :map, doc: "the current logged-in user, if any"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil, doc: "the current theme scope, if any"
  attr :scrollable, :boolean, default: false, doc: "whether content should scroll or fit screen"

  slot :inner_content, required: true

  def app(assigns) do
    # Set responsive height class based on scrollable setting
    height_class = if assigns[:scrollable], do: "min-h-screen", else: "h-screen"
    main_class = "flex-1 flex flex-col p-4"
    dropdown_id = if assigns[:scrollable], do: "dropdown_menu_scrollable", else: "dropdown_menu"
    
    assigns = assign(assigns, height_class: height_class, main_class: main_class, dropdown_id: dropdown_id)
    
    ~H"""
    <div 
      class={"#{@theme} flex flex-1 flex-col #{@height_class} bg-light"}
      id="app-wrapper"
      phx-hook="ThemeHandler"
      data-theme={@theme}
      >
      <header class="flex items-center ml-auto px-4 sm:px-6 lg:px-8">
        <div class="relative py-3 z-10">
          <button 
            class="bg-secondary rounded-full relative border-2 border-accent outline-none focus:outline-none cursor-pointer" 
            type="button" 
            id="user-menu-button" 
            phx-click={JS.toggle(to: "##{@dropdown_id}", in: "fade-in-scale", out: "fade-out-scale")}
            >
            <img src="/images/user-image.svg" alt="User image" class="h-8 w-8 rounded-full border-0 p-1 pointer-events-none">
          </button>
          <div 
            id={@dropdown_id}
            phx-click-away={JS.hide(to: "##{@dropdown_id}")}
            class="absolute right-0 mt-2 w-48 bg-white shadow-xl shadow-secondary border border-secondary hidden" 
            >
            <%= if @current_user do %>
              <.link
                href={dashboard_path(@current_user)}
                class="block px-4 py-2 text-sm text-dark hover:bg-secondary hover:text-light">
                <%= @current_user.first_name || @current_user.username %>
              </.link>
              <hr class="h-px bg-secondary border-0 "/>
              <.link
                href={~p"/users/settings"}
                class="block px-4 py-2 text-sm text-dark hover:bg-secondary hover:text-light"
                >
                Settings
              </.link>
              <hr class="h-px bg-secondary border-0 "/>
              <.link
                href={~p"/users/log_out"}
                class="block px-4 py-2 text-sm text-dark hover:bg-secondary hover:text-light"  
                method="delete">
                Logout
              </.link>
            <% else %>
              <.link
                href={~p"/users/log_in"}
                class="block px-4 py-2 text-sm text-dark hover:bg-secondary hover:text-light"
                >
                Login
              </.link>
              <hr class="h-px bg-secondary border-0 "/>
              <.link
                href={~p"/"}
                class="block px-4 py-2 text-sm text-dark hover:bg-secondary hover:text-light"
                >
                For Devs
              </.link>
            <% end %>
            <hr class="h-px bg-secondary border-0 "/>
            <.live_component 
            module={ElixirAndrewWeb.Component.ThemeSelector} 
            id="theme-selector" 
            theme={@theme}
            class="w-full"
            />
          </div>
        </div>
      </header>
        <main class={@main_class}>
          <.flash_group flash={@flash}/>
          <%= @inner_content %>
        </main>
    </div>
    """
  end

  def dashboard_path(user) do
    case user.role do
      "admin" -> ~p"/dashboard"
      "teacher" -> ~p"/dashboard"
      "student" -> ~p"/student/home"
      _ -> ~p"/"
    end
  end

  embed_templates "layouts/*"
end