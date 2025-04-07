defmodule ElixirAndrew.ProgressesTest do
  use ElixirAndrew.DataCase

  alias ElixirAndrew.Progresses

  describe "progresses" do
    alias ElixirAndrew.Progresses.Progress

    import ElixirAndrew.ProgressesFixtures

    @invalid_attrs %{unit: nil, level: nil, book: nil, reading_question_index: nil, game: nil, prev_tutor: nil, sleeping_tutor: nil}

    test "list_progresses/0 returns all progresses" do
      progress = progress_fixture()
      assert Progresses.list_progresses() == [progress]
    end

    test "get_progress!/1 returns the progress with given id" do
      progress = progress_fixture()
      assert Progresses.get_progress!(progress.id) == progress
    end

    test "create_progress/1 with valid data creates a progress" do
      valid_attrs = %{unit: 42, level: "some level", book: "some book", reading_question_index: 42, game: 42, prev_tutor: 42, sleeping_tutor: 42}

      assert {:ok, %Progress{} = progress} = Progresses.create_progress(valid_attrs)
      assert progress.unit == 42
      assert progress.level == "some level"
      assert progress.book == "some book"
      assert progress.reading_question_index == 42
      assert progress.game == 42
      assert progress.prev_tutor == 42
      assert progress.sleeping_tutor == 42
    end

    test "create_progress/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Progresses.create_progress(@invalid_attrs)
    end

    test "update_progress/2 with valid data updates the progress" do
      progress = progress_fixture()
      update_attrs = %{unit: 43, level: "some updated level", book: "some updated book", reading_question_index: 43, game: 43, prev_tutor: 43, sleeping_tutor: 43}

      assert {:ok, %Progress{} = progress} = Progresses.update_progress(progress, update_attrs)
      assert progress.unit == 43
      assert progress.level == "some updated level"
      assert progress.book == "some updated book"
      assert progress.reading_question_index == 43
      assert progress.game == 43
      assert progress.prev_tutor == 43
      assert progress.sleeping_tutor == 43
    end

    test "update_progress/2 with invalid data returns error changeset" do
      progress = progress_fixture()
      assert {:error, %Ecto.Changeset{}} = Progresses.update_progress(progress, @invalid_attrs)
      assert progress == Progresses.get_progress!(progress.id)
    end

    test "delete_progress/1 deletes the progress" do
      progress = progress_fixture()
      assert {:ok, %Progress{}} = Progresses.delete_progress(progress)
      assert_raise Ecto.NoResultsError, fn -> Progresses.get_progress!(progress.id) end
    end

    test "change_progress/1 returns a progress changeset" do
      progress = progress_fixture()
      assert %Ecto.Changeset{} = Progresses.change_progress(progress)
    end
  end
end
