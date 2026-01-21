defmodule ElixirAndrewWeb.Live.AI.PromptBuilder do
  alias ElixirAndrewWeb.Live.Student.Levels

  @doc """
  Build prompt for crossword clue generation.
  """
  def crossword_prompt(%{
    progress: progress,
    words: words_list,
    max_words: max_words
  }) do
    level_description = Levels.get_level_description(progress)
    
    """
    You are an ESL educational content generator.

    Student level: #{level_description}

    Constraints: 
    - Generate up to #{max_words} words

    Task: 
    Generate clues for a crossword puzzle using these words: #{Enum.join(words_list, ", ")}.

    Rules:
    - Each clue should be simple, student-friendly, and level appropriate.
    - Each clue should be no more than two sentences.
    - Clues should help students learn and remember the word.
    """
  end

  @doc """
  Build prompt for matching game definitions.
  """
  def matching_prompt(%{
    progress: progress,
    words: words_list
  }) do
    level_description = Levels.get_level_description(progress)
    
    """
    You are an ESL educational content generator.

    Student level: #{level_description}

    Task:
    Provide simple, student-friendly definitions for these spelling words: #{Enum.join(words_list, ", ")}.

    Rules:
    - Each definition should be clear and concise (1-2 sentences).
    - Use vocabulary appropriate for the student's level.
    - Avoid using the word itself in the definition.
    - Focus on helping students understand and remember the word.
    """
  end
end