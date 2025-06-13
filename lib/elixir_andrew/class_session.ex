defmodule ElixirAndrew.ClassSession do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias ElixirAndrew.Repo
  alias ElixirAndrew.ClassSession

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "class_sessions" do
    field :date, :date
    field :lesson, :string
    field :homework, :string
    field :spelling_words, {:array, :string}
    belongs_to :student, ElixirAndrew.Accounts.User 

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(class_session, attrs) do
    class_session
    |> cast(attrs, [:date, :lesson, :homework, :spelling_words, :student_id])
    |> validate_required([:date, :lesson, :homework, :spelling_words, :student_id])
  end

  def list_class_sessions(student_id, limit \\ 3, offset \\ 0) do
    from(cs in ClassSession,
      where: cs.student_id == ^student_id,
      order_by: [desc: cs.date],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  def count_class_sessions(student_id) do
    from(cs in ClassSession,
      where: cs.student_id == ^student_id,
      select: count(cs.id)
    )
    |> Repo.one()
  end

  def change_class_session(class_session, attrs \\ %{}) do
    changeset(class_session, attrs)
  end

  def create_class_session(attrs) do
    %ClassSession{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def update_class_session(class_session, attrs) do
    class_session
    |> changeset(attrs)
    |> Repo.update()
  end
end
