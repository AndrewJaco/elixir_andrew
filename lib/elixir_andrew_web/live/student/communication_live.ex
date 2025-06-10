defmodule ElixirAndrewWeb.Student.CommunicationLive do
  use ElixirAndrewWeb, :live_view

  alias ElixirAndrew.ClassSession
  alias ElixirAndrewWeb.Student.CommunicationComponent

  def mount(%{"student_id" => student_id}, _session, socket) do
    # Initial load of 3 class sessions
    class_sessions = ClassSession.list_class_sessions(student_id, 3, 0)
    total_count = ClassSession.count_class_sessions(student_id)
    current_student = ElixirAndrew.Accounts.get_user!(student_id)

    socket = socket
    |> assign(:student_id, student_id)
    |> assign(:current_student, current_student)
    |> assign(:class_sessions, class_sessions)
    |> assign(:page, 1)
    |> assign(:per_page, 3)
    |> assign(:has_more, length(class_sessions) < total_count)

    {:ok, socket}
  end

  def handle_event("load_more", _params, socket) do

    student_id = socket.assigns.student_id
    current_page = socket.assigns.page
    per_page = socket.assigns.per_page
    current_sessions = socket.assigns.class_sessions

    offset = current_page * per_page
    new_sessions = ClassSession.list_class_sessions(student_id, per_page, offset)
    total_count = ClassSession.count_class_sessions(student_id)

    updated_sessions = current_sessions ++ new_sessions

    socket = socket
    |> assign(:class_sessions, updated_sessions)
    |> assign(:page, current_page + 1)
    |> assign(:has_more, length(updated_sessions) < total_count)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="">
      <h1 class="font-bold text-2xl"><%= @current_student.first_name <> " " <> @current_student.last_name || @current_student.username %></h1>
      <h2>Communication Page</h2>
      <ul>
        <%= for session <- @class_sessions do %>
          <li>
            <.live_component
              module={CommunicationComponent}
              id={session.id}
              session={session}
            />
          </li>
        <% end %>
      </ul>
      <%= if @has_more do %>
        <button phx-click="load_more" class="btn btn-primary">Load More</button>
      <% end %>
    </div>
    """
  end

end
