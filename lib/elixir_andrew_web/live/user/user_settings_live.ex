defmodule ElixirAndrewWeb.User.UserSettingsLive do
  use ElixirAndrewWeb, :live_view

  alias ElixirAndrew.Accounts

  def render(assigns) do
    ~H"""
    <div class="px-32 py-4 m-12 border border-dark rounded-lg">
      <.header class="text-center">
        Profile Settings
        <:subtitle>Manage your profile</:subtitle>
      </.header>

      <div class="space-y-12 divide-y">
        <div>
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input field={@email_form[:email]} type="email" label="Email" required />
            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label="Current password"
              value={@email_form_current_password}
              required
            />
            <:actions>
              <.button phx-disable-with="Changing...">Change Email</.button>
            </:actions>
          </.simple_form>
        </div>
        <div> 
          <.simple_form
            for={@name_form}
            id="name_form"
            phx-submit="update_name"
            phx-change="validate_name"
          >
            <.input 
              field={@name_form[:first_name]} 
              type="text" 
              label="First Name"
              value={@current_first_name} />
            <.input 
              field={@name_form[:last_name]} 
              type="text" 
              label="Last Name" 
              value={@current_last_name} />
            <:actions>
              <.button phx-disable-with="Changing...">Change Name</.button>
            </:actions>
          </.simple_form>
        </div>
        <div>
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.input field={@password_form[:password]} type="password" label="New password" required />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
            />
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Current password"
              id="current_password_for_password"
              value={@current_password}
              required
            />
            <:actions>
              <.button phx-disable-with="Changing...">Change Password</.button>
            </:actions>
          </.simple_form>
        </div>
          <div class="w-full flex justify-end pt-4">
            <.link 
              href={ElixirAndrewWeb.Layouts.App.dashboard_path(@current_user)}
              class="text-lg text-gray-600 hover:text-gray-900"
              > Back to Lessons</.link>
          </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    name_changeset = Accounts.change_user_name(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:name_form, to_form(name_changeset))
      |> assign(:current_first_name, user.first_name)
      |> assign(:current_last_name, user.last_name)
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("update_name", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_name(user, user_params) do
      {:ok, updated_user} ->
        name_form =
          updated_user
          |> Accounts.change_user_name(user_params)
          |> to_form()

        {:noreply, 
          socket
          |> put_flash(:info, "Name updated successfully.")
          |> assign(
            name_form: name_form,
            current_first_name: updated_user.first_name,
            current_last_name: updated_user.last_name
          )}

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  def handle_event("validate_name", %{"user" => user_params}, socket) do
    name_changeset = 
      socket.assigns.current_user
      |> Accounts.change_user_name(user_params)
      |> validate_name_format()
      |> Map.put(:action, :validate)
      |> to_form()
    {:noreply, assign(socket, name_form: name_changeset)}
  end

  defp validate_name_format(changeset) do
    changeset
    |> Ecto.Changeset.validate_length(:first_name, min: 1, max: 20)
    |> Ecto.Changeset.validate_length(:last_name, max: 20)
    |> Ecto.Changeset.validate_format(:first_name, ~r/^[a-zA-Z]+$/, message: "only letters allowed")
    |> Ecto.Changeset.validate_format(:last_name, ~r/^[a-zA-Z]+$/, message: "only letters allowed")
  end
end
