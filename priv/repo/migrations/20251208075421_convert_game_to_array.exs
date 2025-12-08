defmodule ElixirAndrew.Repo.Migrations.ConvertGameToArray do
  use Ecto.Migration

  def up do
    # Add new array column
    alter table(:user_progress) do
      add :game_array, {:array, :integer}, default: []
    end

    # Migrate existing data: convert single integer to array
    execute """
    UPDATE user_progress
    SET game_array = ARRAY[game]
    WHERE game IS NOT NULL
    """

    # Remove old column
    alter table(:user_progress) do
      remove :game
    end

    # Rename new column to original name
    rename table(:user_progress), :game_array, to: :game
  end

  def down do
    # Add back integer column
    alter table(:user_progress) do
      add :game_int, :integer
    end

    # Migrate back: take first element from array
    execute """
    UPDATE user_progress
    SET game_int = game[1]
    WHERE game IS NOT NULL AND array_length(game, 1) > 0
    """

    # Remove array column
    alter table(:user_progress) do
      remove :game
    end

    # Rename back to original name
    rename table(:user_progress), :game_int, to: :game
  end
end
