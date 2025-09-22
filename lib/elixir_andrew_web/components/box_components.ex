defmodule ElixirAndrewWeb.BoxComponents do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :class, :string, default: ""
  attr :to, :string, required: true
  slot :inner_block, required: true

  def floating_block_link(assigns) do
    ~H"""
    <div class="container">
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

  attr :class, :string, default: ""
  slot :inner_block, required: true

  def floating_block_static(assigns) do
    ~H"""
    <div class="container">
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