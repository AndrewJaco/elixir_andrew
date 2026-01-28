defmodule ElixirAndrewWeb.Student.SpellingGames.MatchingLive do
  use ElixirAndrewWeb, :live_view

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
    
    socket = 
      socket
      |> assign(:spelling_words, spelling_words)
      # |> initialize_game()

    {:ok, socket}
  end


  def render(assigns) do
    ~H"""
    <div class="matching-game">
      <h1>The Matching Game</h1>
    </div>
    """
  end
end 