defmodule ElixirAndrewWeb.Student.SpellingGames.Crossword.PlacedWord do
  @moduledoc """
  Represents a word placed in the crossword grid with its metadata.
  """
  
  defstruct [:word, :clue, :row, :col, :direction, :number, :length]
  
  @type t :: %__MODULE__{
    word: String.t(),
    clue: String.t(),
    row: integer(),
    col: integer(),
    direction: :across | :down,
    number: integer(),
    length: integer()
  }
end
