defmodule ElixirAndrew.Progresses.Progress do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "progresses" do
    belongs_to :user, ElixirAndrew.Accounts.User

    field :unit, :integer
    field :level, :string
    field :book, :string
    field :reading_question_index, :integer
    field :game, :integer
    field :prev_tutor, :integer
    field :sleeping_tutor, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(progress, attrs) do
    progress
    |> cast(attrs, [:level, :book, :unit, :reading_question_index, :game, :prev_tutor, :sleeping_tutor])
    |> validate_required([:level, :book, :unit, :reading_question_index])
  end
end
