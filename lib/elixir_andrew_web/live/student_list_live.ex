defmodule ElixirAndrewWeb.StudentListLive do
  use Phoenix.LiveView
  alias ElixirAndrew.Accounts

  def mount(_params, _session, _socket) do
    # if connected?(socket) do
    #   current_user = get_current_user(socket)
    #   if current_user.role == "admin" do
    #     user_id = current_user.id
    #   else
    #     {:error, :unauthorized}
    #   end
    # end
    # students = Accounts.list_students(user_id)
    # {:ok, assign(socket, students: students)}
  end


end