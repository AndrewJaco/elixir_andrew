defmodule ElixirAndrewWeb.Student.SpellingGames.ClueGenerator do
  @moduledoc """
  Generates clues for all spelling games using AI.
  """
  require Logger
  alias ElixirAndrew.Progress
  alias ElixirAndrew.ClassSession
  # alias ElixirAndrew.AI.Service  --- IGNORE ---
  
  @min_words 10 
  @doc "Generates clues for a list of words, returns a list of {word, clue} tuples"
  def generate_clues(spelling_words, user_id, :crossword) do  
    Logger.info("=== Crossword Generator Test ===")
    Logger.info("Original spelling words (#{length(spelling_words)}): #{inspect(spelling_words)}")
    
    with {:ok, progress} <- get_progress(user_id) do
      Logger.info("User progress retrieved successfully.")

      # Pad word list if needed
      padded_words = pad_word_list(spelling_words, progress)

      # TEMPORARY: Return mock data to test without AI call
      mock_words_with_clues = Enum.map(padded_words, fn word ->
        %{"word" => word, "clue" => "Mock clue for #{word}"}
      end)
      
      Logger.info("✓ Returning mock data (AI call skipped)")
      {:ok, mock_words_with_clues}

      # Uncomment below to make actual AI call:
      # case Service.generate_crossword(padded_words, progress, max_words: 12) do
      #   {:ok, %{"words" => words_with_clues}} ->
      #     Logger.info("✓ AI Response received!")
      #     Logger.info("Words with clues: #{inspect(words_with_clues, pretty: true)}")
      #     {:ok, words_with_clues}
      
      #   {:error, reason} ->
      #     Logger.error("✗ AI call failed: #{inspect(reason)}")
      #     {:error, reason}
      # end
    end
  end
  
  def generate_clues(spelling_words, user_id, :catch_it) do  
    Logger.info("=== Catch It Generator Test ===")
    Logger.info("Original spelling words (#{length(spelling_words)}): #{inspect(spelling_words)}")
    
    with {:ok, progress} <- get_progress(user_id) do
      Logger.info("User progress retrieved successfully.")
      
      mock_words_with_clues = Enum.map(spelling_words, fn word ->
        %{"word" => word, "clue" => "Mock clue for #{word}"}
      end)
      
      # Uncomment below to make actual AI call:
      # case Service.generate_definitions(spelling_words, progress) do
      #   {:ok, %{"words" => words_with_clues}} ->
      #     Logger.info("✓ AI Response received!")
      #     Logger.info("Words with clues: #{inspect(words_with_clues, pretty: true)}")
      #     {:ok, words_with_clues}
      
      #   {:error, reason} ->
      #     Logger.error("✗ AI call failed: #{inspect(reason)}")
      #     {:error, reason}
      # end

      Logger.info("✓ Returning mock data (AI call skipped)")
      {:ok, mock_words_with_clues}
    end
  end

  defp get_progress(user_id) do
    case Progress.get_user_progress(user_id) do
      nil ->
        Logger.error("No progress found for user #{user_id}")
        {:error, "No progress found"}
      
      progress ->
        {:ok, progress}
    end
  end

  defp pad_word_list(words, progress) when length(words) >= @min_words, do: words
  
  defp pad_word_list(words, progress) do
    needed = @min_words - length(words)
    
    # Get previous spelling words from student's class sessions
    student_id = Map.get(progress, :user_id)
    
    previous_words = if student_id do
      ClassSession.list_class_sessions(student_id, 10)  # Get last 10 sessions
      |> Enum.flat_map(fn session -> session.spelling_words || [] end)
      |> Enum.reject(fn word -> word in words end)  # Remove duplicates
      |> Enum.sort_by(&String.length/1, :desc)  # Prioritize longer words
      |> Enum.take(needed)
    else
      []
    end
    
    words ++ previous_words
  end
end