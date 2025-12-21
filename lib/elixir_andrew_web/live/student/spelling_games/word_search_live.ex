defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearchLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.WordSearchGenerator 
  alias WordSearchGenerator.{Word, Cell}

  def mount(_params, _session, socket) do
    socket = initialize_game(socket)
    {:ok, socket}
  end

  def initialize_game(socket) do
    #change each word in the list of spelling words into a word struct
    words_for_game = Enum.shuffle(socket.assigns.spelling_words)
    |> Enum.map(fn word -> %Word{text: word |> String.replace(" ", "") |> String.upcase()} end)
    
    #prepare the grid
    grid = WordSearchGenerator.create_empty_grid()
    {grid, placed_words} = WordSearchGenerator.place_words(grid, words_for_game, [])
    grid = WordSearchGenerator.fill_empty_cells(grid)
    #get only the words that were placed in the grid for the word bank
    placed_texts = MapSet.new(placed_words, fn word -> word.text end)
    word_bank = Enum.filter(socket.assigns.spelling_words, fn word -> 
      MapSet.member?(placed_texts, word |> String.replace(" ", "") |> String.upcase())
    end)
    IO.inspect(placed_words, label: "Placed words")

    socket 
    |> assign(:word_bank, word_bank)
    |> assign(:words_for_game, placed_words)
    |> assign(:grid, List.flatten(grid))
    |> assign(:found_words, MapSet.new())
    |> assign(:game_state, :intro) # :intro, :in_round, :game_over
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row flex-1 border-2 m-4 p-4 rounded-lg border-accent justify-center items-center gap-8">
      <%!--grid for the game --%>
      <div class="word-search-grid game-shadow">
        <%= for cell <- @grid do %>
          <div class="flex items-center justify-center" >
            <%= cell.letter || "O" %>
          </div>
        <% end %>
        </div>
      <%!-- word bank --%>
      <div class="bg-white border-2 border-primary rounded-lg p-4 game-shadow">
        <h2 class="text-xl font-bold mb-4 text-center">Word Bank</h2>
        <div class="flex flex-wrap lg:flex-nowrap lg:flex-col items-center gap-6 lg:gap-4">
          <%= for word <- @word_bank do %>
            <div class={[
              "",
              MapSet.member?(@found_words, word) && "line-through" || ""
              ]}>
              <%= word %>
            </div>
          <% end %>
          </div>
        </div>
    </div>
    """
  end



end