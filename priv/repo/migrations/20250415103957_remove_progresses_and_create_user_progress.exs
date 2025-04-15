defmodule ElixirAndrew.Repo.Migrations.RemoveProgressesAndCreateUserProgress do
  use Ecto.Migration

  def change do
    #drop the old table
    drop table(:progresses)
  
    create table(:user_progress, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :unit, :integer
      add :level, :string
      add :book, :string
      add :reading_question_index, :integer
      add :game, :integer
      add :prev_tutor, :integer
      add :sleeping_tutor, :integer

      timestamps(type: :utc_datetime)
    end

    #enforces one to one relationship
    create unique_index(:user_progress, [:user_id])
  end
end
