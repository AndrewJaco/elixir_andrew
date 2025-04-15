defmodule ElixirAndrew.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ElixirAndrew.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> ElixirAndrew.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

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
      |> ElixirAndrew.Accounts.create_user_progress()

    user_progress
  end
end
