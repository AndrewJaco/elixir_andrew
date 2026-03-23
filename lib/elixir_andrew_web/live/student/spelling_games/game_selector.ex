defmodule ElixirAndrewWeb.Student.SpellingGames.GameSelector do
  @moduledoc """
  Selects spelling games based on user play history to ensure variety.
  """

  @spelling_games ["hangman", "word_search", "matching", "crossword", "unscramble", "catch_it", "flashcards"]

  @doc """
  Selects the next spelling game based on the user's recent game history.
  
  Avoids games played in the last 3 sessions to provide variety.
  
  ## Parameters
  - `game_history`: List of recently played game indices (1-based)
  - `game_type`: Type of activity - currently only "spelling" is supported
  
  ## Returns
  String name of the selected game
  
  ## Examples
      iex> select_game([1, 2, 3], "spelling")
      "crossword"  # or any game except hangman, word_search, matching
  """
  def select_game(game_history, "spelling") do
    last_three = Enum.take(game_history, 3)
    all_indices = 1..length(@spelling_games)

    remaining_indices = Enum.to_list(all_indices) -- last_three

    # Fallback: if all games played recently, allow all games
    pool = if Enum.empty?(remaining_indices), do: Enum.to_list(all_indices), else: remaining_indices

    selected_index = Enum.random(pool)
    Enum.at(@spelling_games, selected_index - 1)
  end

  def select_game(_game_history, _game_type), do: "hangman"

  @doc """
  Returns list of all available spelling games.
  """
  def available_games, do: @spelling_games

  @doc """
  Selects a fallback game that doesn't require AI generation.
  
  Used when AI-based games (crossword, matching) fail to generate.
  
  ## Parameters
  - `game_history`: List of recently played game indices
  
  ## Returns
  String name of a non-AI game
  """
  def select_fallback_game(game_history) do
    # Non-AI games: hangman, word_search, unscramble, catch_it, flashcards
    # Exclude: crossword, matching (which require AI)
    non_ai_games = ["hangman", "word_search", "unscramble", "catch_it", "flashcards"]
    
    # Get games not recently played
    recent_games = Enum.take(game_history, 3)
    available_games = Enum.reject(non_ai_games, &(&1 in recent_games))
    
    # If all have been played recently, just pick randomly from non-AI games
    if Enum.empty?(available_games) do
      Enum.random(non_ai_games)
    else
      Enum.random(available_games)
    end
  end
end
