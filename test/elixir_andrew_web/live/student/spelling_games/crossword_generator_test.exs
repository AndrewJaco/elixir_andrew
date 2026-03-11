defmodule ElixirAndrewWeb.Live.SpellingGames.CrosswordGeneratorTest do
  use ExUnit.Case, async: true
  
  alias ElixirAndrewWeb.Live.SpellingGames.CrosswordGenerator

  describe "generate/1" do
    test "generates crossword with simple words" do
      words_clues = [
        %{"word" => "cat", "clue" => "Feline pet"},
        %{"word" => "car", "clue" => "Vehicle"},
        %{"word" => "tar", "clue" => "Sticky substance"}
      ]

      result = CrosswordGenerator.generate(words_clues)

      assert {:ok, state} = result
      assert is_map(state.grid)
      assert length(state.placements) == 3
      
      # Verify all words were placed
      placed_words = Enum.map(state.placements, & &1.word)
      assert "CAT" in placed_words
      assert "CAR" in placed_words
      assert "TAR" in placed_words
    end

    test "handles words with spaces" do
      words_clues = [
        %{"word" => "ice cream", "clue" => "Cold dessert"}
      ]

      result = CrosswordGenerator.generate(words_clues)

      assert {:ok, state} = result
      assert [placement] = state.placements
      # Should normalize to "ICECREAM"
      assert placement.word == "ICECREAM"
    end

    test "places first word in center" do
      words_clues = [
        %{"word" => "hello", "clue" => "Greeting"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)

      [placement] = state.placements
      grid_size = CrosswordGenerator.grid_size()
      
      # First word should be centered
      assert placement.row == div(grid_size, 2)
      assert placement.direction == :across
    end

    test "words intersect at common letters" do
      words_clues = [
        %{"word" => "cat", "clue" => "Pet"},
        %{"word" => "art", "clue" => "Creative work"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)

      # Find the shared 'A' position
      cat_placement = Enum.find(state.placements, &(&1.word == "CAT"))
      art_placement = Enum.find(state.placements, &(&1.word == "ART"))

      refute is_nil(cat_placement)
      refute is_nil(art_placement)

      # Verify words share at least one grid cell
      cat_cells = get_word_cells(cat_placement)
      art_cells = get_word_cells(art_placement)

      shared_cells = MapSet.intersection(MapSet.new(cat_cells), MapSet.new(art_cells))
      assert MapSet.size(shared_cells) > 0
    end

    test "returns error tuple when placement fails" do
      # Two words that don't share any letters 
      words_clues = [
        %{"word" => "xxxxx", "clue" => "All x's"},
        %{"word" => "yyyyy", "clue" => "All y's"}  
      ]

      result = CrosswordGenerator.generate(words_clues)
      
      # Should fail gracefully
      assert result == :fail
    end

    test "handles empty word list" do
      result = CrosswordGenerator.generate([])

      assert {:ok, state} = result
      assert state.grid == %{}
      assert state.placements == []
    end

    test "grid structure contains coordinate tuples as keys" do
      words_clues = [
        %{"word" => "cat", "clue" => "Pet"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)

      # All grid keys should be {row, col} tuples
      assert Enum.all?(Map.keys(state.grid), fn key ->
        match?({row, col} when is_integer(row) and is_integer(col), key)
      end)

      # All grid values should be single uppercase letters
      assert Enum.all?(Map.values(state.grid), fn value ->
        is_binary(value) and String.length(value) == 1 and value =~ ~r/^[A-Z]$/
      end)
    end

    test "grid contains correct letters for placed word" do
      words_clues = [
        %{"word" => "dog", "clue" => "Pet"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)
      [placement] = state.placements

      # Get expected positions for "DOG"
      expected_positions = get_word_cells(placement)
      
      # Verify grid has letters at those positions
      assert Map.get(state.grid, Enum.at(expected_positions, 0)) == "D"
      assert Map.get(state.grid, Enum.at(expected_positions, 1)) == "O"
      assert Map.get(state.grid, Enum.at(expected_positions, 2)) == "G"
    end

    test "result contains placements with correct structure" do
      words_clues = [
        %{"word" => "cat", "clue" => "Pet"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)
      [placement | rest] = state.placements

      assert is_map(placement)
      assert Map.has_key?(placement, :word)
      assert Map.has_key?(placement, :clue)
      assert Map.has_key?(placement, :row)
      assert Map.has_key?(placement, :col)
      assert Map.has_key?(placement, :direction)

      assert placement.word == "CAT"
      assert placement.clue == "Pet"
    end

    test "grid size matches number of placed letters" do
      words_clues = [
        %{"word" => "cat", "clue" => "Pet"},
        %{"word" => "car", "clue" => "Vehicle"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)

      # Grid should have at most (and usually less than) total letters
      # because of shared letters at intersections
      total_letters = String.length("CAT") + String.length("CAR")
      grid_cell_count = map_size(state.grid)
      
      assert grid_cell_count > 0
      assert grid_cell_count <= total_letters
    end

    test "placements list structure contains required fields" do
      words_clues = [
        %{"word" => "test", "clue" => "Examination"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)
      [placement] = state.placements

      assert Map.has_key?(placement, :word)
      assert Map.has_key?(placement, :clue)
      assert Map.has_key?(placement, :row)
      assert Map.has_key?(placement, :col)
      assert Map.has_key?(placement, :direction)
      
      assert placement.word == "TEST"
      assert placement.clue == "Examination"
      assert is_integer(placement.row)
      assert is_integer(placement.col)
      assert placement.direction in [:across, :down]
    end

    test "preserves clues in placements" do
      words_clues = [
        %{"word" => "dog", "clue" => "Man's best friend"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)

      [placement] = state.placements
      assert placement.clue == "Man's best friend"
    end

    test "sorts words by length (longest first)" do
      words_clues = [
        %{"word" => "a", "clue" => "Letter A"},
        %{"word" => "cat", "clue" => "Pet"},
        %{"word" => "elephant", "clue" => "Large animal"}
      ]

      {:ok, state} = CrosswordGenerator.generate(words_clues)

      # Longest word should be placed first (in center)
      first_placement = List.last(state.placements)
      assert first_placement.word == "ELEPHANT"
    end
  end

  describe "grid_size/0" do
    test "returns configured grid size" do
      assert CrosswordGenerator.grid_size() == 15
    end
  end

  # Helper function to get all grid cells occupied by a word
  defp get_word_cells(placement) do
    word_length = String.length(placement.word)
    
    for i <- 0..(word_length - 1) do
      case placement.direction do
        :across -> {placement.row, placement.col + i}
        :down -> {placement.row + i, placement.col}
      end
    end
  end
end
