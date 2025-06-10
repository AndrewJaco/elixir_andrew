defmodule ElixirAndrew.Repo.Migrations.CreateClassSessions do
  use Ecto.Migration

  def change do
    create table(:class_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :date, :date
      add :lesson, :text
      add :homework, :text
      add :spelling_words, {:array, :string}
      add :student_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:class_sessions, [:student_id])
  end
end
