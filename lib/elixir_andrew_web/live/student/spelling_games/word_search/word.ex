defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearch.Word do
  @moduledoc """
  Represents a word in the word search puzzle with its placement metadata.
  """
  
  defstruct text: "", uppercase_text: "", path: [], direction: {0, 0}, found: false
  
  @type t :: %__MODULE__{
    text: String.t(),
    uppercase_text: String.t(),
    path: list({integer(), integer()}),
    direction: {integer(), integer()},
    found: boolean()
  }
end
