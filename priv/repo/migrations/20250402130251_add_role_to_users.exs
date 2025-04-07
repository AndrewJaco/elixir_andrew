defmodule ElixirAndrew.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "student"  # "student", "admin", or "guest"
    end
  end
end
