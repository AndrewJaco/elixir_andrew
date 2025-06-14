defmodule ElixirAndrew.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :first_name, :string
    field :last_name, :string
    field :age, :integer
    field :theme, :string, default: "theme-default"
    field :role, :string, default: "student"

    has_many :class_sessions, ElixirAndrew.ClassSession, foreign_key: :student_id

    belongs_to :teacher, ElixirAndrew.Accounts.User, foreign_key: :teacher_id
    has_many :students, ElixirAndrew.Accounts.User, foreign_key: :teacher_id

    has_one :user_progress, ElixirAndrew.Progress.UserProgress

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username, :password, :teacher_id, :role])
    |> validate_username(opts)
    |> validate_password(opts)
    |> validate_teacher_student_relationship()
  end

  defp validate_username(changeset, _opts) do
    changeset
    |> validate_required([:username])
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "can only contain letters, numbers, and underscores")
    |> validate_length(:username, min: 3, max: 20)
    |> unsafe_validate_unique(:username, ElixirAndrew.Repo)
    |> unique_constraint(:username)
  end

  defp validate_optional_email(changeset) do
    email = get_field(changeset, :email)
   
    if email do
      changeset
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
      |> validate_length(:email, max: 160)
  
    else 
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for updating the profile.
  It requires the username and first name to be present.
  It also validates the username format and length.
  It checks for uniqueness of the username, but only if it has changed.
  """

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :first_name, :last_name])
    |> validate_required([:username, :first_name])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_length(:first_name, min: 2, max: 20)
    |> validate_length(:last_name, min: 2, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "can only contain letters, numbers, and underscores")
    |> unsafe_validate_unique(:username, ElixirAndrew.Repo)
    |> unique_constraint(:username)
  end

  @doc """
  A user changeset for updating the profile's name only.
  It doesn't require the last name to be present.
  """
  def name_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name])
    |> validate_required([:first_name])
    |> validate_length(:first_name, min: 2, max: 20)
    |> validate_length(:last_name, min: 2, max: 20)   
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, _opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_optional_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role, :teacher_id])
    |> validate_inclusion(:role, ["admin", "teacher", "student"])
    |> validate_teacher_student_relationship()
  end

  defp validate_teacher_student_relationship(changeset) do
    role = get_field(changeset, :role)
    teacher_id = get_field(changeset, :teacher_id)

    case {role, teacher_id} do
      {role, teacher_id} when (role=== "admin" or role==="teacher") and not is_nil(teacher_id) ->
        add_error(changeset, :teacher_id, "admin and teacher cannot have a teacher")
      _ ->
        changeset
    end
  end
  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%ElixirAndrew.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
