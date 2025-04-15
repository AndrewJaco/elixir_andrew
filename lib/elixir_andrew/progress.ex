defmodule ElixirAndrew.Progress do
  @moduledoc """
  The Progress context.
  """

  import Ecto.Query, warn: false
  alias ElixirAndrew.Repo

  alias ElixirAndrew.Progress.UserProgress

  @doc """
  Returns the list of user_progress.

  ## Examples

      iex> list_user_progress()
      [%UserProgress{}, ...]

  """
  def list_user_progress do
    Repo.all(UserProgress)
  end

  @doc """
  Gets a single user_progress.

  Raises `Ecto.NoResultsError` if the User progress does not exist.

  ## Examples

      iex> get_user_progress!(123)
      %UserProgress{}

      iex> get_user_progress!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_progress!(id), do: Repo.get!(UserProgress, id)

  @doc """
  Creates a user_progress.

  ## Examples

      iex> create_user_progress(%{field: value})
      {:ok, %UserProgress{}}

      iex> create_user_progress(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_progress(user, attrs \\ %{}) do
    user
    |> UserProgress.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_progress.

  ## Examples

      iex> update_user_progress(user_progress, %{field: new_value})
      {:ok, %UserProgress{}}

      iex> update_user_progress(user_progress, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_progress(%UserProgress{} = user_progress, attrs) do
    user_progress
    |> UserProgress.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_progress.

  ## Examples

      iex> delete_user_progress(user_progress)
      {:ok, %UserProgress{}}

      iex> delete_user_progress(user_progress)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_progress(%UserProgress{} = user_progress) do
    Repo.delete(user_progress)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_progress changes.

  ## Examples

      iex> change_user_progress(user_progress)
      %Ecto.Changeset{data: %UserProgress{}}

  """
  def change_user_progress(%UserProgress{} = user_progress, attrs \\ %{}) do
    UserProgress.changeset(user_progress, attrs)
  end
end
