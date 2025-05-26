defmodule ElixirAndrewWeb.Layouts.App do
  use ElixirAndrewWeb, :html
  alias Phoenix.LiveView.JS

  def toggle_dropdown_menu do
    JS.toggle(
      to: "#dropdown_menu",
      in: {"transition ease-out duration-100", "transform opacity-0 translate-y-[-10%]", "transform opacity-100 translate-y-0"},
      out: {"transition ease-in duration-75", "transform opacity-100 translate-y-0", "transform opacity-0 translate-y-[-10%]"}
    )
  end

  def dashboard_path(user) do
    case user.role do
      "admin" -> ~p"/dashboard"
      "teacher" -> ~p"/dashboard"
      "student" -> ~p"/student/home"
      _ -> ~p"/"
    end
  end
end