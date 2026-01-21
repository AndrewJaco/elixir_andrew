defmodule ElixirAndrewWeb.Live.Student.AI.Schemas.MatchingSchema do
  @moduledoc """
  Defines the expected JSON structure for AI-generated word definitions for matching game.
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
          "required" => ["word", "definition"],
          "properties" => %{
            "word" => %{
              "type" => "string",
              "description" => "The spelling word."
            },
            "definition" => %{
              "type" => "string",
              "description" => "A simple, student-friendly definition."
            }
          }
        }
      }
    }
  }

  def schema, do: @schema
end
