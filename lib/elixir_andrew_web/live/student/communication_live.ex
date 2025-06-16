defmodule ElixirAndrewWeb.Student.CommunicationLive do
  use ElixirAndrewWeb, :live_view

  alias ElixirAndrew.ClassSession
  alias ElixirAndrewWeb.Student.CommunicationFormComponent

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
    |> assign(:show_new_form, false)
    |> assign(:new_session, %ClassSession{student_id: student_id})

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="flex gap-12 mb-4">
        <div>
          <h1 class="font-bold text-2xl"><%= display_name(@current_student) %> </h1>
          <h2>Communication Page</h2>
        </div>
        <div class="mb-4">
          <button 
            phx-click="new_session" 
            class="btn-primary btn-effect"
            disabled={@show_new_form}
            >
            New Class</button>
        </div>
        <.link navigate={~p"/dashboard/students"} class="btn-primary btn-effect ml-auto text-center h-fit">
          Back to Students
        </.link>

      </div>

        <%= if @show_new_form do %>
          <.live_component
            module={CommunicationFormComponent}
            id="new_session_form"
            session={@new_session}
            is_new={true}
            class="mb-4"
          />
        <% end %>

      <ul class="justify-center flex flex-col gap-4 ">
        <%= for session <- @class_sessions do %>
          <li>
            <.live_component
              module={CommunicationFormComponent}
              id={session.id}
              session={session}
              is_new={false}
            />
          </li>
        <% end %>
      </ul>
      <%= if @has_more do %>
        <button phx-click="load_more" class="mt-4 btn-primary btn-effect">Load More</button>
      <% end %>
    </div>
    """
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


  def handle_event("new_session", _params, socket) do
    new_session = %ClassSession{student_id: socket.assigns.student_id}

    {:noreply,
      socket
      |> assign(:new_session, new_session)
      |> assign(:show_new_form, true)}
  end

  def handle_info({:session_created, session}, socket) do
    updated_sessions = [session | socket.assigns.class_sessions]
    |> Enum.sort_by(& &1.date, :desc)

    {:noreply,
      socket
      |> assign(:class_sessions, updated_sessions)
      |> assign(:show_new_form, false)
      |> put_flash(:info, "Class session created successfully.")
    }   
  end

  def handle_info({:cancel_new_session}, socket) do
    {:noreply, 
      socket 
      |> assign(:new_session, %ClassSession{student_id: socket.assigns.student_id})
      |> assign(:show_new_form, false)}
  end

  defp display_name(user) do
    full_name = "#{user.first_name || ""} #{user.last_name || ""}" |> String.trim()
    if full_name == "", do: user.username, else: full_name
  end
end
