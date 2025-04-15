defmodule ElixirAndrew.ProgressFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ElixirAndrew.Progress` context.
  """

  @doc """
  Generate a user_progress.
  """
  def user_progress_fixture(attrs \\ %{}) do
    {:ok, user_progress} =
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
      |> ElixirAndrew.Progress.create_user_progress()

    user_progress
  end
end
