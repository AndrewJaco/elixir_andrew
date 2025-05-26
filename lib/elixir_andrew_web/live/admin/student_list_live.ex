defmodule ElixirAndrewWeb.Admin.StudentListLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrew.Accounts

  def mount(_params, _session, socket) do
    teacher = socket.assigns[:current_user]

    students = 
      if teacher && teacher.role == "teacher" || teacher.role == "admin" do
        Accounts.list_students(teacher.id)
      else
        []
      end

    {:ok, assign(socket, students: students)}
  end

end