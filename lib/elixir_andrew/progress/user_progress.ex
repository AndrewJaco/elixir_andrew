defmodule ElixirAndrew.Progress.UserProgress do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_progress" do
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
  def changeset(user_progress, attrs) do
    user_progress
    |> cast(attrs, [:unit, :level, :book, :reading_question_index, :game, :prev_tutor, :sleeping_tutor])
    |> validate_required([:unit, :level, :book])
  end
end
