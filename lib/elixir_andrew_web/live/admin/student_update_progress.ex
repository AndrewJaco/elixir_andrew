defmodule ElixirAndrewWeb.Admin.StudentUpdateProgress do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrew.Progress
  alias ElixirAndrew.Progress.UserProgress
  alias ElixirAndrew.Accounts
  require Logger

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"student_id" => student_id}, _url, socket) do
    student = Accounts.get_user!(student_id)
    progress = Progress.get_user_progress(student.id)
    
    # If no progress exists, create a new struct with user_id
    progress = progress || %UserProgress{user_id: student.id}
    
    # Create a changeset for the form
    changeset = UserProgress.changeset(progress, %{})

    {:noreply, assign(socket, student: student, progress: progress, form: to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold mb-4">Update Progress for <%= @student.first_name %></h1>
      <.simple_form 
        for={@form} 
        id="update-progress-form"
        phx-submit="update_progress"
        >
        <.input
          field={@form[:level]}
          type="text"
          label="Level (grade/CEFR level): ex. 6/B2"
          />
        <.input
          field={@form[:unit]}
          type="text"
          label="Unit"
          />
        <.input
          field={@form[:book]}
          type="text"
          label="Book"
          />
        <:actions>
          <.button>Update Progress</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("update_progress", %{"user_progress" => progress_params}, socket) do
    progress = socket.assigns.progress
    student = socket.assigns.student
    
    # Check if this is a new record (no id yet) or existing
    result = if progress.id do
      Progress.update_user_progress(progress, progress_params)
    else
      # Add user_id to params for new records
      Progress.create_user_progress(Map.put(progress_params, "user_id", student.id))
    end
    
    Logger.info("Result: #{inspect(result)}")
    
    case result do
      {:ok, updated_progress} ->
        Logger.info("Success! Navigating to dashboard. Updated: #{inspect(updated_progress.id)}")
        {:noreply,
         socket
         |> put_flash(:info, "Progress updated successfully.")
         |> push_navigate(to: ~p"/dashboard")}
      
      {:error, changeset} ->
        Logger.error("Failed to update: #{inspect(changeset.errors)}")
        {:noreply, 
         socket
         |> put_flash(:error, "Failed to update progress: #{inspect(changeset.errors)}")
         |> assign(form: to_form(changeset))}
    end
  end
end