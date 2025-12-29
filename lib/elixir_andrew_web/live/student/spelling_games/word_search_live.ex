defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearchLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.WordSearchGenerator 
  alias WordSearchGenerator.{Word, Cell}

  def mount(_params, _session, socket) do
    socket = initialize_game(socket)
    {:ok, socket}
  end

  defp initialize_game(socket) do
    #change each word in the list of spelling words into a word struct
    words_for_game = Enum.shuffle(socket.assigns.spelling_words)
    |> Enum.map(fn word -> %Word{uppercase_text: word |> String.replace(" ", "") |> String.upcase(), text: word} end)
    
    #prepare the grid
    grid = WordSearchGenerator.create_empty_grid()
    {grid, placed_words} = WordSearchGenerator.place_words(grid, words_for_game, [])
    grid = WordSearchGenerator.fill_empty_cells(grid)

    #get only the words that were placed in the grid for the word bank
    placed_texts = MapSet.new(placed_words, fn word -> word.text end)
    placed_words = Enum.filter(placed_words, fn word -> MapSet.member?(placed_texts, word.text) end)
    
    # IO.inspect(grid, label: "Final Grid")

    socket 
    # |> assign(:word_bank, word_bank)
    |> assign(:words_for_game, placed_words)
    |> assign(:grid, List.flatten(grid))
    |> assign(:game_state, :intro) # :intro, :in_round, :game_over
  end

  def render(assigns) do
    ~H"""
    
    <%= if @game_state == :intro || @game_state == :in_round do %>
    <div class="flex flex-col lg:flex-row flex-1 border-2 m-4 p-4 rounded-lg border-accent justify-center items-center gap-8">
      <%!--grid for the game --%>
      <div class="word-search-grid game-shadow" phx-hook="WordSearch" id="word-search-grid" style={"--grid-size: #{WordSearchGenerator.grid_size()}"}}>
        <%= for cell <- @grid do %>
          <div 
            class={"flex items-center justify-center word-search-cell" <> (if cell.found, do: " border-2 border-green-500" , else: "")} 
            data-row={cell.row} 
            data-col={cell.col}
            data-letter={cell.letter}
            data-found={cell.found}
            >
            <%= cell.letter || "O" %>
          </div>
        <% end %>
        </div>
      <%!-- word bank --%>
      <div class="bg-white border-2 border-primary rounded-lg p-4 game-shadow">
        <h2 class="text-xl font-bold mb-4 text-center">Word Bank</h2>
        <div class="flex flex-wrap lg:flex-nowrap lg:flex-col items-center gap-6 lg:gap-4">
          <%= for word <- @words_for_game do %>
            <div class={"text-lg " <> (if word.found, do: "line-through", else: "")}>
              <%= word.text %>
            </div>
          <% end %>
          </div>
        </div>
    </div>
    <% end %>

    <%= if @game_state == :game_over do %>
      <div class="absolute inset-0 bg-opacity-50 flex items-center justify-center">
        <div class="bg-white p-8 rounded-lg text-center game-shadow">
          <h1 class="text-3xl font-bold mb-4">Congratulations!</h1>
          <p class="mb-6">You found all the words!</p>
          <button phx-click="restart_game" class="btn btn-primary">Play Again</button>
        </div>
      </div>
    <% end %>
    """
  end

  def handle_event("check_word", %{"path" => path}, socket) do
  #compare path to each word's path
  #if any path is equal, mark word as found
  #check if all words are found and end game
    IO.inspect(path, label: "Selected path")
    path_tuples = Enum.map(path, fn %{"row" => row, "col" => col} -> {row, col} end)
    reversed_path = Enum.reverse(path_tuples)
    
    socket = 
      Enum.reduce(socket.assigns.words_for_game, socket, fn word, acc_socket ->
        if (word.path == path_tuples or word.path == reversed_path) and not word.found do
          #mark word as found
          updated_word = %Word{word | found: true}
          updated_words = Enum.map(acc_socket.assigns.words_for_game, fn w -> 
            if w.text == word.text, do: updated_word, else: w
          end)
          #mark cells as found
          updated_grid = Enum.map(acc_socket.assigns.grid, fn cell ->
            if Enum.any?(word.path, fn {r, c} -> r == cell.row and c == cell.col end) do
              %Cell{cell | found: true}
            else
              cell
            end
          end)
          assign(acc_socket, words_for_game: updated_words, grid: updated_grid)
        else
          acc_socket
        end
      end)

    is_game_over?(socket)
  end

  def handle_event("restart_game", _params, socket) do
    socket = initialize_game(socket)
    {:noreply, socket}
  end

  defp is_game_over?(socket) do
    if Enum.any?(socket.assigns.words_for_game, fn word -> not word.found end) do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :game_state, :game_over)}
    end
  end

end

