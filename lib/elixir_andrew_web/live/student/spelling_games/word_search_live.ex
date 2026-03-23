defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearchLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.WordSearchGenerator 
  alias ElixirAndrewWeb.Student.SpellingGames.WordSearch.{Word, Cell}

  @impl true
  def mount(params, _session, socket) do
    # Get spelling words from URL params or fallback to empty list
    spelling_words = case params["spelling_words"] do
      nil -> []
      words when is_binary(words) -> 
        words
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
      words when is_list(words) -> words
    end
    
    socket = 
      socket
      |> assign(:spelling_words, spelling_words)
      |> initialize_game()
      
    welcome_timer = Process.send_after(self(), :start_game, 2000)
    socket = assign(socket, :welcome_timer, welcome_timer)
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

    socket 
    |> assign(:words_for_game, placed_words)
    |> assign(:grid_2d, grid)
    |> assign(:grid, List.flatten(grid))
    |> assign(:game_state, :intro) # :intro, :in_round, :game_over
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @game_state == :intro do %>
      <div class="flex flex-col items-center justify-center flex-1">
        <div id="intro-title" class="text-primary text-center">
          <h1 class="text-4xl font-bold">Word Search</h1>
        </div>
        <div id="intro-instructions" class="text-accent text-center">
          <h2 class="text-3xl">Find all the words!</h2>
        </div>
      </div>
    <% end %>

    <%= if @game_state in [:in_round, :game_over] do %>
    <div 
      class="wordsearch-game flex flex-col lg:flex-row flex-1 border-2 m-4 p-4 rounded-lg border-accent justify-center items-center gap-8"
      phx-hook="WordSearch"
      id="word-search-wrapper"
      data-grid={Jason.encode!(@grid_2d)}
      data-grid-size={WordSearchGenerator.grid_size()}
    >
      <%!--grid for the game --%>
      <div class="relative">
        <svg
          class="absolute inset-0 z-10 pointer-events-none"
          width="100%"
          height="100%"
          style={""}
          phx-update="ignore"
          id="word-search-svg"
        >
          <path id="preview-path" />
        </svg>
        <div 
          class={"word-search-grid game-shadow" <> (if @game_state == :game_over, do: " pointer-events-none", else: "")}
          id="word-search-grid" 
          style={"--grid-size: #{WordSearchGenerator.grid_size()}"}
        >
        <%= for cell <- @grid do %>
          <div 
            class="flex items-center justify-center word-search-cell"
            data-row={cell.row} 
            data-col={cell.col}
            data-letter={cell.letter}
            data-found={cell.found}
            >
            <%= cell.letter || "O" %>
          </div>
        <% end %>
        </div>
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
    
      <%= if @game_state == :game_over do %>
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="p-8 border-2 border-alert rounded-lg text-center game-shadow wordsearch-modal">
            <h1 class="text-3xl font-bold mb-4">Congratulations!</h1>
            <p class="mb-6">You found all the words!</p>
            <button phx-click="restart_game" class="btn btn-primary">Play Again</button>
            <.link navigate={~p"/student/home"} class="btn btn-alert ml-4">Exit</.link>
          </div>
        </div>
      <% end %>
    <% end %>
    """
  end

  @impl true
  def handle_event("check_word", %{"path" => _path}, %{assigns: %{game_state: :game_over}} = socket) do
    {:noreply, socket}
  end

  def handle_event("check_word", %{"path" => path}, socket) do
    path_tuples = Enum.map(path, fn %{"row" => row, "col" => col} -> {row, col} end)
    reversed_path = Enum.reverse(path_tuples)
    
    {socket, word_found} = 
      Enum.reduce(socket.assigns.words_for_game, {socket, false}, fn word, {acc_socket, found} ->
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
          {assign(acc_socket, words_for_game: updated_words, grid: updated_grid), true}
        else
          {acc_socket, found}
        end
      end)

    socket = if word_found do
      push_event(socket, "keep-path", %{})
    else
      push_event(socket, "clear-path", %{})
      socket
    end

    # Check if game is complete and transition state
    if Enum.all?(socket.assigns.words_for_game, fn word -> word.found end) do
      {:noreply, assign(socket, :game_state, :game_over)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("restart_game", _params, socket) do
    socket = initialize_game(socket)
    Process.send_after(self(), :start_game, 3000)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:start_game, socket) do
    {:noreply, assign(socket, :game_state, :in_round)}
  end

end

