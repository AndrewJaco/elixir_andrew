defmodule ElixirAndrewWeb.Live.SpellingGames.CrosswordGenerator do
  alias ElixirAndrewWeb.Live.Student.AI.Service
  require Logger

  def generate_crossword(spelling_words, progress) do
    Logger.info("=== Crossword Generator Test ===")
    Logger.info("Spelling words: #{inspect(spelling_words)}")
    Logger.info("Progress level: #{inspect(progress.level)}")

    # Call the AI service to generate clues
    case Service.generate_crossword(spelling_words, progress, max_words: 12) do
      {:ok, %{"words" => words_with_clues}} ->
        Logger.info("✓ AI Response received!")
        Logger.info("Words with clues: #{inspect(words_with_clues, pretty: true)}")
        {:ok, words_with_clues}

      {:error, reason} ->
        Logger.error("✗ AI call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

end