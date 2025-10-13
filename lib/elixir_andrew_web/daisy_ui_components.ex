defmodule ElixirAndrewWeb.DaisyUIComponents do
  @doc false
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(helpers())
    end
  end

  @doc false
  def component do
    quote do
      use Phoenix.Component

      unquote(helpers())
    end
  end

  defp helpers() do
    quote do
      import ElixirAndrewWeb.DaisyUIComponents.Utils
      import ElixirAndrewWeb.DaisyUIComponents.JSHelpers

      alias Phoenix.LiveView.JS
    end
  end

  @doc """
  Used for functional or live components
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(opts) do
    core_components = Keyword.get(opts, :core_components, true)

    quote do
      unquote(
        if core_components do
          quote do
            import ElixirAndrewWeb.DaisyUIComponents.Button
            import ElixirAndrewWeb.DaisyUIComponents.Flash
            import ElixirAndrewWeb.DaisyUIComponents.Form
            import ElixirAndrewWeb.DaisyUIComponents.Icon
            import ElixirAndrewWeb.DaisyUIComponents.Header
            import ElixirAndrewWeb.DaisyUIComponents.Input
            import ElixirAndrewWeb.DaisyUIComponents.JSHelpers
            import ElixirAndrewWeb.DaisyUIComponents.List
            import ElixirAndrewWeb.DaisyUIComponents.Table
          end
        end
      )

      import ElixirAndrewWeb.DaisyUIComponents.Accordion
      import ElixirAndrewWeb.DaisyUIComponents.Alert
      import ElixirAndrewWeb.DaisyUIComponents.Avatar
      import ElixirAndrewWeb.DaisyUIComponents.Back
      import ElixirAndrewWeb.DaisyUIComponents.Badge
      import ElixirAndrewWeb.DaisyUIComponents.Breadcrumbs
      import ElixirAndrewWeb.DaisyUIComponents.Card
      import ElixirAndrewWeb.DaisyUIComponents.Checkbox
      import ElixirAndrewWeb.DaisyUIComponents.Collapse
      import ElixirAndrewWeb.DaisyUIComponents.Drawer
      import ElixirAndrewWeb.DaisyUIComponents.Dropdown
      import ElixirAndrewWeb.DaisyUIComponents.Fieldset
      import ElixirAndrewWeb.DaisyUIComponents.Footer
      import ElixirAndrewWeb.DaisyUIComponents.Hero
      import ElixirAndrewWeb.DaisyUIComponents.Indicator
      import ElixirAndrewWeb.DaisyUIComponents.Join
      import ElixirAndrewWeb.DaisyUIComponents.Label
      import ElixirAndrewWeb.DaisyUIComponents.Loading
      import ElixirAndrewWeb.DaisyUIComponents.Menu
      import ElixirAndrewWeb.DaisyUIComponents.Modal
      import ElixirAndrewWeb.DaisyUIComponents.Navbar
      import ElixirAndrewWeb.DaisyUIComponents.Pagination
      import ElixirAndrewWeb.DaisyUIComponents.Progress
      import ElixirAndrewWeb.DaisyUIComponents.Radio
      import ElixirAndrewWeb.DaisyUIComponents.Range
      import ElixirAndrewWeb.DaisyUIComponents.Select
      import ElixirAndrewWeb.DaisyUIComponents.Stat
      import ElixirAndrewWeb.DaisyUIComponents.Swap
      import ElixirAndrewWeb.DaisyUIComponents.Tabs
      import ElixirAndrewWeb.DaisyUIComponents.TextInput
      import ElixirAndrewWeb.DaisyUIComponents.Textarea
      import ElixirAndrewWeb.DaisyUIComponents.Toggle
      import ElixirAndrewWeb.DaisyUIComponents.Tooltip
    end
  end
end
