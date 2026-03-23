defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearch.Cell do
  @moduledoc """
  Represents a single cell in the word search grid.
  """
  
  @derive Jason.Encoder
  defstruct letter: "", row: 0, col: 0, found: false
  
  @type t :: %__MODULE__{
    letter: String.t() | nil,
    row: integer(),
    col: integer(),
    found: boolean()
  }
end
