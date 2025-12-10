defmodule ElixirAndrew.Repo.Migrations.TrimSpellingWordsWhitespace do
  use Ecto.Migration

  def up do
    # Trim whitespace from all spelling words in class_sessions
    execute """
    UPDATE class_sessions
    SET spelling_words = ARRAY(
      SELECT TRIM(word)
      FROM UNNEST(spelling_words) AS word
      WHERE TRIM(word) != ''
    )
    WHERE spelling_words IS NOT NULL
    """
  end

  def down do
    # No need to restore whitespace
    :ok
  end
end
