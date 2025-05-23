defmodule ElixirAndrew.Repo.Migrations.UpdateExistingUserRoles do
  use Ecto.Migration

  def change do
    execute("UPDATE users SET role = 'student' WHERE role IS NULL")

    execute("""
      UPDATE users 
      SET role = 'student' 
      WHERE role NOT IN ('admin', 'student', 'teacher')
    """)

    execute("""
      ALTER TABLE users
      ADD CONSTRAINT role_check
      CHECK (role IN ('admin', 'student', 'teacher'))
    """)
  end

end
