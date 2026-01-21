defmodule ElixirAndrewWeb.Live.SpellingGames.CrosswordGenerator do
  alias ElixirAndrewWeb.Live.Student.Levels

  def generate_crossword(spelling_words, progress) do
    prompt = ElixirAndrewWeb.Live.AI.PromptBuilder.crossword_prompt(progress: progress, words: spelling_words, max_words: 12)

    #Call the AI service with the prompt and get the response
  end

end