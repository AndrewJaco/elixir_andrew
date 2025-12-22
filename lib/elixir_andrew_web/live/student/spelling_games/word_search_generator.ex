defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearchGenerator do
  @grid_size 14
  defmodule Word do
    defstruct text: "", uppercase_text: "", path: [], direction: {0,0}, found: false
  end
  
  defmodule Cell do
    defstruct letter: "", row: 0, col: 0, found: false
  end

  def create_empty_grid() do
    grid_size = @grid_size
    for row <- 0..grid_size-1 do
      for col <- 0..grid_size-1 do
        %Cell{letter: nil, row: row, col: col, found: false}
      end
    end
  end

  def place_words(grid, [], placed_words), do: {grid, Enum.reverse(placed_words)}
  def place_words(grid, [word | rest], placed_words) do 
    case try_place_word(grid, word, 100) do
      {:ok, updated_grid, placed_word} -> 
        place_words(updated_grid, rest, [placed_word | placed_words])
      {:error, :failed_to_place_word} -> 
        place_words(grid, rest, placed_words)
    end
  end

  def try_place_word(_grid, _word, 0), do: {:error, :failed_to_place_word}
  def try_place_word(grid, word, attempts_left) do

    {row_dir, col_dir} = generate_direction()
    start_row = :rand.uniform(@grid_size) - 1
    start_col = :rand.uniform(@grid_size) - 1
    word_of_cells = Enum.map(Enum.with_index(String.graphemes(word.uppercase_text)), fn {letter, index} ->
      %Cell{letter: letter, row: start_row + (index * row_dir), col: start_col + (index * col_dir)}
    end)

    # check if cell is in bounds
    in_bounds = Enum.all?(word_of_cells, fn letter_cell -> 
      letter_cell.row >= 0 and letter_cell.row < @grid_size and
      letter_cell.col >= 0 and letter_cell.col < @grid_size
    end)

    # check if cell is available
    unique_cells = if in_bounds, do: Enum.all?(word_of_cells, fn letter -> cell_available?(grid, letter) end), else: false
    
    if not in_bounds or not unique_cells do
      # IO.inspect("Retrying placement for word #{word.text}, attempts left: #{attempts_left - 1}")
      try_place_word(grid, word, attempts_left - 1)
    else
      path = Enum.into(word_of_cells, [], fn letter -> {letter.row, letter.col} end)
      placed_word = %Word{word | path: path, direction: {row_dir, col_dir}}
      updated_grid = place_word_in_grid(grid, placed_word)
      # IO.inspect(word_of_cells, label: "Word of cells")
    {:ok, updated_grid, placed_word} 
    end
  end

  defp generate_direction() do
    directions = [{0,1}, {1,0}, {1,1}, {1,-1}, {0,-1}, {-1,0}, {-1,1}, {-1,-1}]
    Enum.random(directions)
  end

  defp cell_available?(grid, letter) do
    cell = Enum.at(Enum.at(grid, letter.row), letter.col)
    cell.letter == nil or cell.letter == letter.letter
  end


  defp place_word_in_grid(grid, word) do
    path = word.path
    text_chars = String.graphemes(word.uppercase_text)
    
    updated_grid = Enum.reduce(Enum.with_index(path), grid, fn {{row, col}, idx}, acc_grid ->
      letter = Enum.at(text_chars, idx)
      List.update_at(acc_grid, row, fn grid_row ->
        List.update_at(grid_row, col, fn cell ->
          %Cell{cell | letter: letter}
        end)
      end)
    end)
    updated_grid
  end

  def fill_empty_cells(grid) do
    Enum.map(grid, fn row ->
      Enum.map(row, fn cell ->
        if cell.letter == nil do
          random_letter = <<Enum.random(65..90)>> 
          %Cell{cell | letter: random_letter}
        else
          cell
        end
      end)
    end)
  end
end