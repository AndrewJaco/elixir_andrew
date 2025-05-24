defmodule ElixirAndrew.Repo.Migrations.AddMissingTeacherIdColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :teacher_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    end
    
    create index(:users, [:teacher_id])
  end
end