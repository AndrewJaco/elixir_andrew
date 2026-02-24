defmodule ElixirAndrewWeb.Live.SpellingGames.CrosswordGenerator do
  alias ElixirAndrewWeb.Live.Student.AI.Service
  require Logger

  @spec generate_crossword(list(String.t()), map()) :: {:ok, list(map())} | {:error, term()}
  def generate_crossword(spelling_words, progress) do
    Logger.info("=== Crossword Generator Test ===")
    Logger.info("Spelling words: #{inspect(spelling_words)}")
    Logger.info("Progress: #{inspect(progress)}")
    Logger.info("Progress level: #{inspect(progress.level)}")
    Logger.info("Progress book: #{inspect(progress.book)}")
    Logger.info("Progress unit: #{inspect(progress.unit)}")

    # TEMPORARY: Return mock data to test without AI call
    # mock_words_with_clues = Enum.map(spelling_words, fn word ->
    #   %{"word" => word, "clue" => "Mock clue for #{word}"}
    # end)
    
    # Logger.info("✓ Returning mock data (AI call skipped)")
    # {:ok, mock_words_with_clues}

    # Uncomment below to make actual AI call:
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