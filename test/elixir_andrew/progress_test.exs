defmodule ElixirAndrew.ProgressTest do
  use ElixirAndrew.DataCase

  alias ElixirAndrew.Progress

  describe "user_progress" do
    alias ElixirAndrew.Progress.UserProgress

    import ElixirAndrew.ProgressFixtures

    @invalid_attrs %{unit: nil, level: nil, book: nil, reading_question_index: nil, game: nil, prev_tutor: nil, sleeping_tutor: nil}

    test "list_user_progress/0 returns all user_progress" do
      user_progress = user_progress_fixture()
      assert Progress.list_user_progress() == [user_progress]
    end

    test "get_user_progress!/1 returns the user_progress with given id" do
      user_progress = user_progress_fixture()
      assert Progress.get_user_progress!(user_progress.id) == user_progress
    end

    test "create_user_progress/1 with valid data creates a user_progress" do
      valid_attrs = %{unit: 42, level: "some level", book: "some book", reading_question_index: 42, game: 42, prev_tutor: 42, sleeping_tutor: 42}

      assert {:ok, %UserProgress{} = user_progress} = Progress.create_user_progress(valid_attrs)
      assert user_progress.unit == 42
      assert user_progress.level == "some level"
      assert user_progress.book == "some book"
      assert user_progress.reading_question_index == 42
      assert user_progress.game == 42
      assert user_progress.prev_tutor == 42
      assert user_progress.sleeping_tutor == 42
    end

    test "create_user_progress/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Progress.create_user_progress(@invalid_attrs)
    end

    test "update_user_progress/2 with valid data updates the user_progress" do
      user_progress = user_progress_fixture()
      update_attrs = %{unit: 43, level: "some updated level", book: "some updated book", reading_question_index: 43, game: 43, prev_tutor: 43, sleeping_tutor: 43}

      assert {:ok, %UserProgress{} = user_progress} = Progress.update_user_progress(user_progress, update_attrs)
      assert user_progress.unit == 43
      assert user_progress.level == "some updated level"
      assert user_progress.book == "some updated book"
      assert user_progress.reading_question_index == 43
      assert user_progress.game == 43
      assert user_progress.prev_tutor == 43
      assert user_progress.sleeping_tutor == 43
    end

    test "update_user_progress/2 with invalid data returns error changeset" do
      user_progress = user_progress_fixture()
      assert {:error, %Ecto.Changeset{}} = Progress.update_user_progress(user_progress, @invalid_attrs)
      assert user_progress == Progress.get_user_progress!(user_progress.id)
    end

    test "delete_user_progress/1 deletes the user_progress" do
      user_progress = user_progress_fixture()
      assert {:ok, %UserProgress{}} = Progress.delete_user_progress(user_progress)
      assert_raise Ecto.NoResultsError, fn -> Progress.get_user_progress!(user_progress.id) end
    end

    test "change_user_progress/1 returns a user_progress changeset" do
      user_progress = user_progress_fixture()
      assert %Ecto.Changeset{} = Progress.change_user_progress(user_progress)
    end
  end
end
