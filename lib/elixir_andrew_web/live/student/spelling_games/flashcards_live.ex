defmodule ElixirAndrewWeb.Student.SpellingGames.FlashcardsLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.Crossword.ClueCache

  @impl true
  def mount(params, _session, socket) do
    spelling_words = case params["spelling_words"] do
      nil -> []
      words when is_binary(words) -> 
        words
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      words when is_list(words) -> words
    end
    
    # Check if clues were pre-generated and retrieve from cache
    pregenerated_clues = case params["clue_cache_key"] do
      key when is_binary(key) -> ClueCache.pop(key)
      _ -> nil
    end
    
    socket =
      socket
      |> assign(:spelling_words, spelling_words)
      |> assign(:game_state, if(pregenerated_clues, do: :ready, else: :loading))
      |> assign(:error, nil)
      |> assign(:words_with_clues, pregenerated_clues)
    
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flashcards-game">
      <h1>Flashcards</h1>
      <ul>
        <%= for %{word: word, definition: definition} <- @words_with_clues || [] do %>
          <li>
            <strong><%= word %></strong>: <%= definition %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def get_definitions(words, _progress) do
    # Placeholder for AI call to get definitions for flashcards
    # In a real implementation, this would call an external API or service
    list = Enum.map(words, fn word -> 
      %{word: word, definition: "Definition of #{word}"}
    end)
    {:ok, list}
  end
end