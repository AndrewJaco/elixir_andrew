defmodule ElixirAndrew.Repo.Migrations.AddThemeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :theme, :string, default: "theme-default"
    end

    # Add a default theme for existing users  
    execute("UPDATE users SET theme = 'theme-default' WHERE theme IS NULL")
    # Add a default theme for new users
    execute("ALTER TABLE users ALTER COLUMN theme SET DEFAULT 'theme-default'")
    # Add a check constraint to ensure the theme is one of the allowed values
    execute("""
      ALTER TABLE users
      ADD CONSTRAINT theme_check
      CHECK (theme IN ('theme-default', 'theme-mc', 'theme-hk', 'theme-lg'))
    """)
  end
end
