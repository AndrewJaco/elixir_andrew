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
    if is_nil(user_progress_params["id"]) do
      create_user_progress(user_progress_params, socket)
    else
      update_user_progress(user_progress_params, socket)
    end
  end
  
  def handle_event("validate", %{"user_progress" => user_progress_params}, socket) do
    changeset =
      %UserProgress{}
      |> Progress.change_user_progress(user_progress_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  defp create_user_progress(user_progress_params, socket) do

    case Progress.create_user_progress(user_progress_params) do
      {:ok, _user_progress} ->
        {:noreply, socket |> put_flash(:info, "User progress created successfully.") |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end`

  defp update_user_progress(user_progress_params, socket) do
    case Progress.update_user_progress(user_progress_params) do
      {:ok, _user_progress} ->
        {:noreply, socket |> put_flash(:info, "User progress updated successfully.") |> push_navigate(to: ~p"/")}

      {:error, message} ->
        socket = put_flash(socket, :error, message)
        {:noreply, socket}
    end
  end
end