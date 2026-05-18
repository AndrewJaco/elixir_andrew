defmodule ElixirAndrewWeb.Live.Student.AI.Schemas.DefinitionsSchema do
  @moduledoc """
  Defines the expected JSON structure for AI-generated word definitions for catch it game or other matching games.
  """

  @type word_entry :: %{String.t() => String.t()}
  @type t :: %{String.t() => list(word_entry())}

  # JSON Schema for OpenAI structured output

  @schema %{
    "type" => "object",
    "required" => ["words"],
    "properties" => %{
      "words" => %{
        "type" => "array",
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
              "description" => "A simple, student-friendly clue."
            }
          }
        }
      }
    }
  }

  def schema, do: @schema
end
