defmodule ElixirAndrew.SpellingGames do
  
  @moduledoc """
  Module for selecting spelling games based on user history.

  ## Functions

  - 'select_game/2': Selects the next spelling game based on the user's game history.

  """

  @doc """
  Selects the next spelling game type based on the user's game history.
  ## Parameters
  - game_history: A list representing the user's past game history.
  - game_type: A string representing the type of activity. ex. "spelling", "reading", "grammar"

  ## Returns
  - A string representing the selected game.
  """
  def select_game(game_history, game_type) do
    available_games = case game_type do
      "spelling" -> ["hangman", "word_search", "matching", "crossword", "unscramble", "catch_it", "flashcards"]
      _ -> ["default_game"]
    end

    last_three = Enum.take(game_history, 3)
    all_games = Enum.to_list(1..length(available_games))

    remaining_games = all_games -- last_three

    #fallback: if there are no remaining games, allow all games
    pool = 
      case remaining_games do
        [] -> all_games
        _ -> remaining_games
      end

    selected_index = Enum.random(pool)
    Enum.at(available_games, selected_index - 1)
  end

  # def save_game_results(user_progress, new_game_index) do
  #   updated_game_history = [new_game_index | user_progress.game || []]
  #   Ecto.Changeset.change(user_progress, game: updated_game_history)
  # end
end