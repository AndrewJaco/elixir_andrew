defmodule ElixirAndrew.ProgressesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ElixirAndrew.Progresses` context.
  """

  @doc """
  Generate a progress.
  """
  def progress_fixture(attrs \\ %{}) do
    {:ok, progress} =
      attrs
      |> Enum.into(%{
        book: "some book",
        game: 42,
        level: "some level",
        prev_tutor: 42,
        reading_question_index: 42,
        sleeping_tutor: 42,
        unit: 42
      })
      |> ElixirAndrew.Progresses.create_progress()

    progress
  end
end
