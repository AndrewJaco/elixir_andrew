defmodule ElixirAndrew.Repo.Migrations.CreateProgresses do
  use Ecto.Migration

  def change do
    create table(:progresses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :level, :string
      add :book, :string
      add :unit, :integer
      add :reading_question_index, :integer
      add :game, :integer
      add :prev_tutor, :integer
      add :sleeping_tutor, :integer
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:progresses, [:user_id])
  end
end
