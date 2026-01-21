defmodule ElixirAndrewWeb.Live.Student.AI.Schemas.CrosswordSchema do
  @moduledoc """
  Defines the expected JSON structure for AI-generated crossword clues.
  """

  @type word_entry :: %{
          "word" => String.t(),
          "definition" => String.t()
        }
  @type t :: %{
          "words" => [word_entry()]
        }

  @schema %{
    "type" => "object",
    "required" => ["words"],
    "properties" => %{
      "words" => %{
        "type" => "array",
        "minItems" => 3,
        "maxItems" => 12,
        "items" => %{
          "type" => "object",
          "required" => ["word", "clue"],
          "properties" => %{
            "word" => %{
              "type" => "string",
              "description" => "The spelling word."
            },
            "clue" => %{
              "type" => "string",
              "description" => "A simple, student-friendly clue for a crossword puzzle."
            }
          }
        }
      }
    }
  }

  def schema, do: @schema
end