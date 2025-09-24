defmodule ElixirAndrewWeb.BoxComponents do
  @moduledoc """
  Provides 3D floating block UI components.
  
  These components can be used to create a visually engaging interface"
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renders a 3D floating block that acts as a link.
  
  ## Attributes
    * `:class` - Additional CSS classes for styling the block.
    * `:to` - The URL to navigate to when the block is clicked.
  ## Slots
    * `:inner_block` - The content to be displayed inside the block.

  ## Classes
    You can pass custom classes to style the block. Some example classes:
      * `small` - Renders a smaller block.
      * `rectangle` - Renders a rectangular block.
      * `lrg` - Renders a larger block.
      * `cube` - Renders a cube-shaped block.

    ## Examples
    
      <.floating_block_link to="/some/path" class="rectangle small">
        Click Me
      </.floating_block_link> 
  """
  attr :class, :string, default: ""
  attr :to, :string, required: true
  slot :inner_block, required: true

  def floating_block_link(assigns) do
    ~H"""
    <div class="block-container">
      <div class={"floating-block clickable #{@class}"} phx-click={JS.navigate(@to)}>
        <div class="face top"></div>
        <div class="face right"></div>
        <div class="face bottom"></div>
        <div class="face left"></div>
        <div class="face back"></div>
        <div class="face front">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a static 3D floating block.
  ## Attributes
    * `:class` - Additional CSS classes for styling the block.
  ## Slots
    * `:inner_block` - The content to be displayed inside the block.
  ## Classes
    You can pass custom classes to style the block. Some example classes:
      * `small` - Renders a smaller block.
      * `rectangle` - Renders a rectangular block.
      * `lrg` - Renders a larger block.
      * `cube` - Renders a cube-shaped block.
    ## Examples
      <.floating_block_static class="rectangle small">
        Static Content
      </.floating_block_static>
  """
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def floating_block_static(assigns) do
    ~H"""
    <div class="block-container">
      <div class={"floating-block #{@class}"}>
        <div class="face top"></div>
        <div class="face right"></div>
        <div class="face bottom"></div>
        <div class="face left"></div>
        <div class="face back"></div>
        <div class="face front">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end
end