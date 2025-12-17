defmodule ElixirAndrewWeb.Student.SpellingGames.WordSearchLive do
  use ElixirAndrewWeb, :live_view
  @grid_size 14

  defmodule Word do
    defstruct text: "", path: [], direction: {0, 1}, found: false
  end
  
  defmodule Cell do
    defstruct letter: "", row: 0, col: 0, found: false
  end

  def mount(_params, _session, socket) do
    socket = 
      socket
      |> initialize_game()
    
    {:ok, socket}
  end

  def initialize_game(socket) do
    #change each word in the list of spelling words into a word struct
    words_for_game = Enum.shuffle(socket.assigns.spelling_words)
    |> Enum.map(fn word -> %__MODULE__.Word{text: word |> String.replace(" ", "") |> String.upcase()} end)

    word_bank = Enum.take(socket.assigns.spelling_words, 10)  
    
    grid = create_grid()

    socket 
    |> assign(:word_bank, word_bank)
    |> assign(:words_for_game, words_for_game)
    |> assign(:grid, grid)
    |> assign(:found_words, MapSet.new())
    |> assign(:game_state, :intro) # :intro, :in_round, :game_over
  end

  
  def render(assigns) do
    ~H"""
    <div class="word-search-container">
      <div class="word-search-grid">
        <%= for row <- @grid, cell <- row do %>
          <div class={["grid-cell", cell.found && "found"]}>
            <%= cell.letter %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp create_grid() do
    # Placeholder function to create a grid with the given words
    # Actual implementation would involve placing words in a grid and filling in random letters
    grid_size = 14
    
    for row <- 0..grid_size-1 do
      for col <- 0..grid_size-1 do
        %__MODULE__.Cell{letter: <<Enum.random(?A..?Z)>>, row: row, col: col, found: false}
      end
    end
  end

  defp generate_direction(word) do
    #give a Word a random direction from a set of possible directions
    directions = [{0,0}, {0,1}, {1,0}, {1,1}, {1,-1}, {0,-1}, {-1,0}, {-1,1}, {-1,-1}]
    %{word | direction: Enum.random(directions)}
  end

  defp place_word_in_grid(grid, word) do
    # Placeholder function to place a word in the grid at a specified position and direction
    grid
  end

end