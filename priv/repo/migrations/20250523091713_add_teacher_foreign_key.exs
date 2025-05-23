defmodule ElixirAndrew.Repo.Migrations.AddTeacherForeignKey do
  use Ecto.Migration

  def change do
    # Add teacher_id column with foreign key reference
    # alter table(:users) do
    #   add :teacher_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    # end
    
    # Create index for performance
    # create index(:users, [:teacher_id])
    
    # Remove existing role constraint if it exists 
    # execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS role_check")
    
    # Add the role check constraint
    # execute("""
    #   ALTER TABLE users
    #   ADD CONSTRAINT role_check
    #   CHECK (role IN ('admin', 'student', 'teacher'))
    # """)
  end
end