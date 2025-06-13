defmodule ElixirAndrewWeb.User.UserRegistrationLive do
  use ElixirAndrewWeb, :live_view

  alias ElixirAndrew.Accounts
  alias ElixirAndrew.Accounts.User

  def mount(_params, _session, socket) do

    registration_type = case socket.assigns.live_action do
      :new_teacher ->"teacher"
      :new_student -> "student"
      _ -> "student"
    end

    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign(registration_type: registration_type)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end
  
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <%= if @registration_type == "teacher" do %>
          Register a new teacher
        <% else %>
          Register a new student
        <% end %>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:username]} type="text" label="Username" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <%= if @registration_type == "teacher" do %>
          <.input field={@form[:email]} type="email" label="Email" required />
        <% end %>

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = case socket.assigns.registration_type do
      "teacher" ->
        user_params 
        |> Map.put("role", "teacher")
        |> Map.put("teacher_id", nil) # Teachers do not have a teacher_id

      "student" ->
        user_params 
        |> Map.put("teacher_id", socket.assigns.current_user.id) # Current logged in teacher will be assigned to the student
        |> Map.put("role", "student")

      _ ->
        user_params
    end
    
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_registration(%User{})

        redirect_path = if socket.assigns.registration_type == "teacher" do
          ~p"/dashboard"
        else
          ~p"/users/#{user.id}/progress/new"
        end

        {:noreply, 
          socket 
          |> put_flash(:info, "User Created.") 
          |> assign_form(changeset) 
          |> push_navigate(to: redirect_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
