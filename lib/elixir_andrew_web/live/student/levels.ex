defmodule ElixirAndrewWeb.Student.Levels do
  @moduledoc """
  Provides level descriptions for AI context when generating content for students.
  Level format: "grade/proficiency" (e.g., "6/B1")
  """

  @level_descriptions %{
    "PREA1" => "complete beginner with very basic vocabulary",
    "A1" => "beginner with basic vocabulary and simple sentence structures",
    "A2" => "elementary with expanding vocabulary and simple grammar",
    "B1" => "intermediate with conversational fluency and moderate complexity",
    "B2" => "upper-intermediate with strong comprehension and varied expression",
    "C1" => "advanced with sophisticated language and nuanced understanding",
    "C2" => "proficient with near-native fluency"
  }

  def get_level_description(progress) do
    case String.split(progress.level, "/", parts: 2) do
      [grade, level] ->
        level_upper = String.upcase(level)
        level_detail = Map.get(@level_descriptions, level_upper, "intermediate (unknown level #{level_upper})")
        "Student is in grade #{grade} and is a #{level_detail} English language learner (CEFR #{level_upper}). Use vocabulary and sentence complexity appropriate for this level."
      
      _ ->
        "Student is an English language learner. Use clear, grade-appropriate language."
    end
  end
end