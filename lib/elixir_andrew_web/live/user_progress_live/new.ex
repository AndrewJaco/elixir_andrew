defmodule ElixirAndrewWeb.UserProgressLive.New do
  use ElixirAndrewWeb, :live_view

  alias ElixirAndrew.Progress
  alias ElixirAndrew.Progress.UserProgress
  alias ElixirAndrew.Accounts

  def mount(%{"user_id" => user_id}, _session, socket) do
    user = Accounts.get_user!(user_id)
    changeset = Progress.change_user_progress(%UserProgress{user_id: user.id})
    form = to_form(changeset, as: "user_progress")

    {:ok, assign(socket, user: user, changeset: changeset, form: form)}
  end

  def handle_event("save", %{"user_progress" => user_progress_params}, socket) do
    user_progress_params = 
      if Map.has_key?(user_progress_params, "user_id") do
        user_progress_params
      else
        Map.put(user_progress_params, "user_id", socket.assigns.user.id)
      end
    
    if is_nil(user_progress_params["id"]) do
      create_user_progress(user_progress_params, socket)
    else
      update_user_progress(user_progress_params, socket)
    end

  end
  
  def handle_event("validate", %{"user_progress" => user_progress_params}, socket) do
    user_progress_params = 
      if Map.has_key?(user_progress_params, "user_id") do
        user_progress_params
      else
        Map.put(user_progress_params, "user_id", socket.assigns.user.id)
      end

    changeset =
      %UserProgress{user_id: socket.assigns.user.id}
      |> Progress.change_user_progress(user_progress_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  defp create_user_progress(user_progress_params, socket) do
    user_progress_params = Map.put(user_progress_params, "user_id", socket.assigns.user.id)

    case Progress.create_user_progress(user_progress_params) do
      {:ok, _user_progress} ->
        {:noreply, socket |> put_flash(:info, "User progress created successfully.") |> push_navigate(to: ~p"/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message = changeset_error_to_string(changeset)

        {:noreply, 
          socket
          |> put_flash(:error, "Failed to create progress: #{error_message}")
          |> assign(changeset: changeset)
          |> assign(:form, to_form(changeset))}
    end
  end

  defp changeset_error_to_string(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, message} -> "#{field}: #{message}" end)
    |> Enum.join(", ")
  end

  defp update_user_progress(user_progress_params, socket) do
    case Progress.update_user_progress(socket.assigns.user, user_progress_params) do
      {:ok, _user_progress} ->
        {:noreply, socket |> put_flash(:info, "User progress updated successfully.") |> push_navigate(to: ~p"/dashboard")}

      {:error, message} ->
        socket = put_flash(socket, :error, message)
        {:noreply, socket}
    end
  end
end