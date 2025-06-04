defmodule ElixirAndrewWeb.Admin.StudentEditLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrew.Accounts

  def mount(%{"user_id" => student_id}, _session, socket) do
    student = Accounts.get_user!(student_id)
    name_changeset = Accounts.change_user_profile(student)

    socket =
      socket
      |> assign(student: student)
      |> assign(name_form: to_form(name_changeset))
      |> assign(trigger_submit: false)

    {:ok, socket}
  end

  def handle_event("update_name", params, socket) do
    student = socket.assigns.student
    %{"user" => user_params} = params

    case Accounts.update_user_profile(student, user_params) do
      {:ok, updated_user} ->
        name_form =
          updated_user
          |> Accounts.change_user_profile(user_params)
          |> to_form()

        {:noreply, 
          socket
          |> put_flash(:info, "Name updated successfully.")
          |> assign( name_form: name_form)
        }

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  def handle_event("validate_name", %{"user" => user_params}, socket) do
    profile_changeset = 
      socket.assigns.student
      |> Accounts.change_user_profile(user_params)
      |> validate_name_format()
      |> Map.put(:action, :validate)
      
    {:noreply, assign(socket, name_form: to_form(profile_changeset))}
  end

  def handle_event("remove_student", _params, socket) do
    student = socket.assigns.student

    case Accounts.remove_student_from_teacher(student) do
      {:ok, _updated_user} ->
        {:noreply, 
          socket
          |> put_flash(:info, "Student removed successfully.")
          |> push_navigate(to: ~p"/dashboard/students")
        }

      {:error, message} when is_binary(message) ->
        {:noreply, 
          socket
          |> put_flash(:error, message)
        }

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply,
            socket
            |> put_flash(:error, "Failed to remove student: #{inspect(changeset.errors)}")}
    end
  end

  defp validate_name_format(changeset) do
    changeset
    |> Ecto.Changeset.validate_length(:first_name, min: 1, max: 20)
    |> Ecto.Changeset.validate_length(:last_name, max: 20)
    |> Ecto.Changeset.validate_format(:first_name, ~r/^[a-zA-Z\s\-']+$/, message: "only letters or - and ' allowed")
    |> Ecto.Changeset.validate_format(:last_name, ~r/^[a-zA-Z\s\-']+$/, message: "only letters or - and ' allowed")
  end
end