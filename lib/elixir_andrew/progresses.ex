defmodule ElixirAndrew.Progresses do
  @moduledoc """
  The Progresses context.
  """

  import Ecto.Query, warn: false
  alias ElixirAndrew.Repo

  alias ElixirAndrew.Progresses.Progress

  @doc """
  Returns the list of progresses.

  ## Examples

      iex> list_progresses()
      [%Progress{}, ...]

  """
  def list_progresses do
    Repo.all(Progress)
  end

  @doc """
  Gets a single progress.

  Raises `Ecto.NoResultsError` if the Progress does not exist.

  ## Examples

      iex> get_progress!(123)
      %Progress{}

      iex> get_progress!(456)
      ** (Ecto.NoResultsError)

  """
  def get_progress!(id), do: Repo.get!(Progress, id)

  @doc """
  Creates a progress.

  ## Examples

      iex> create_progress(%{field: value})
      {:ok, %Progress{}}

      iex> create_progress(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_progress(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:progresses)
    |> Progress.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a progress.

  ## Examples

      iex> update_progress(progress, %{field: new_value})
      {:ok, %Progress{}}

      iex> update_progress(progress, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_progress(%Progress{} = progress, attrs) do
    progress
    |> Progress.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a progress.

  ## Examples

      iex> delete_progress(progress)
      {:ok, %Progress{}}

      iex> delete_progress(progress)
      {:error, %Ecto.Changeset{}}

  """
  def delete_progress(%Progress{} = progress) do
    Repo.delete(progress)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking progress changes.

  ## Examples

      iex> change_progress(progress)
      %Ecto.Changeset{data: %Progress{}}

  """
  def change_progress(%Progress{} = progress, attrs \\ %{}) do
    Progress.changeset(progress, attrs)
  end
end
