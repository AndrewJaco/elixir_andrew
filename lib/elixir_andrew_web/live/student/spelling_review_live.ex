defmodule ElixirAndrewWeb.Student.SpellingReviewLive do
  use ElixirAndrewWeb, :live_view
  alias ElixirAndrewWeb.Student.SpellingGames.GameSelector
  alias ElixirAndrewWeb.Student.SpellingGames.Crossword.ClueCache

  def mount(params, _session, socket) do
    student_id = socket.assigns.current_user.id
    
    # Get spelling words from socket assigns (from hook) or fall back to URL params
    spelling_words = case socket.assigns[:spelling_words] do
      nil -> 
        # Parse from URL params if not set by hook
        case params["spelling_words"] do
          nil -> []
          words when is_binary(words) -> 
            words
            |> String.split(",")
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))
          words when is_list(words) -> words
        end
      words when is_list(words) -> words
      _ -> []
    end
    
    socket = socket
      |> assign(:student_id, student_id)
      |> assign(:spelling_words, spelling_words)
      |> assign(:current_index, -1)
      |> assign(:current_word, List.first(spelling_words))
      |> assign(:current_text, "Review first!")
      |> assign(:timer_ref, nil)
      |> assign(:auto_advance, true)
      |> assign(:view_state, :welcome)
      |> assign(:timer_progress, 0)
      |> assign(:progress_timer_ref, nil)
      |> assign(:clues, nil)
      |> assign(:clue_generation_status, :not_started)

    # Only select game on connected mount to avoid double selection
    if connected?(socket) do
      user_progress = ElixirAndrew.Progress.get_user_progress(student_id)
      game_history = if user_progress, do: user_progress.game || [], else: []
      
      selected_game = GameSelector.select_game(game_history, "spelling")
      IO.puts("Selected Game: #{selected_game}")

      socket = socket
        |> assign(:game_history, game_history)
        |> assign(:selected_game, selected_game)
        |> assign(:user_progress, user_progress)

      # Start background generation of clues for games that need it
      if selected_game in ["crossword", "flashcards", "catch_it"] do
        send(self(), :generate_clues)
      end

      welcome_timer = Process.send_after(self(), :start_review, 5000)
      {:ok, assign(socket, :welcome_timer, welcome_timer)}
    else
      # Disconnected mount - set defaults
      socket = socket
        |> assign(:game_history, [])
        |> assign(:selected_game, nil)
        |> assign(:user_progress, nil)
        |> assign(:welcome_timer, nil)
      
      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col border border-solid border-accent border-4 p-8 m-4">
      <%= case @view_state do %>
        <% :welcome -> %>
          <h2 class="self-center text-3xl text-dark font-bold mb-4">Time to review your spelling words</h2>
          <div class="flex flex-col flex-1 items-center justify-center my-4 border border-solid border-2 rounded-xl border-primary p-4">
            <p class="mb-8 text-2xl font-semibold"> <%= @current_text %> </p>
            <button phx-click="start_review" class="btn btn-primary" > Okay!</button>
          </div>
      
        <% :review -> %>
          <div class="flex flex-col flex-1 items-center space-x-4 my-4 border border-solid border-2 rounded-xl border-primary p-4">
            <div class="flex flex-col flex-1"> 
              <div class="flex flex-col items-center">
                <p class="text-sm mb-2" ><%= @current_index + 1 %> / <%= length(@spelling_words) %></p>
                <progress class="progress progress-primary rounded-full h-4 w-56" value={@current_index + 1} max={length(@spelling_words)}></progress>
              </div>
              <div class="flex flex-col flex-1 justify-center items-center">
                <p class="text-3xl font-semibold"><%= @current_text %></p>
              </div>
            </div>
            <div class="my-4 border border-solid border-2 border-primary p-4 rounded-full relative">
              <progress class="progress progress-primary rounded-full h-full absolute left-0 top-0 z-1" style="transition: value 0.5s ease-in-out;" value={if @auto_advance, do: @timer_progress, else: 0} max="100"></progress>
              <div class="flex space-x-4 relative z-10">
                <button phx-click="prev_word" class="btn btn-primary flex items-center justify-center" disabled={@current_index == 0}>
                  <.icon name="hero-chevron-left-solid" class="h-5 w-5"/>
                </button>
                <button phx-click="toggle_pause" class="btn btn-primary flex items-center justify-center">
                  <%= if @auto_advance do %>
                    <.icon name="hero-pause-solid" class="h-5 w-5"/>
                  <% else %>
                    <.icon name="hero-play-solid" class="h-5 w-5"/>
                  <% end %>
                </button>
                <button phx-click="next_word" class="btn btn-primary flex items-center justify-center">
                  <.icon name="hero-chevron-right-solid" class="h-5 w-5"/>
                </button>
              </div>
            </div>
          </div>

        <% :completed -> %>
          <div class="flex flex-col flex-1 my-4 border border-solid border-2 rounded-xl border-primary p-8">
            <h2 class="flex-1 text-center text-3xl text-dark font-bold"> <%= @current_text %> </h2>
            <ul class={[
              "flex-3 self-center list-disc list-inside my-6",
              cond do
                length(@spelling_words) > 15 -> "columns-4 gap-8"
                length(@spelling_words) > 10 -> "columns-3 gap-8"
                length(@spelling_words) > 5 -> "columns-2 gap-8"
                true -> ""
              end
            ]}>
              <%= for word <- @spelling_words do %>
                <li class="text-xl"><%= word %></li>
              <% end %>
            </ul>
            <div class="flex flex-col space-y-4 flex-2 mx-8">
              <button phx-click="restart" class="flex-1 px-4 py-2 bg-secondary text-white gem-btn secondary">Review Again</button>
                  <%= if @selected_game == "crossword" and @clue_generation_status == :generating do %>
                <button disabled class="flex-4 px-4 py-2 bg-base-300 text-base-content gem-btn">
                  <span class="loading loading-spinner loading-sm"></span>
                  Preparing Crossword...
                </button>
              <% else %>
                <button phx-click="start_game" class="flex-4 px-4 py-2 bg-accent text-white gem-btn accent">Start Spelling Game</button>
              <% end %>
            </div>
          </div>
      <% end %>
      <div>
        <a href={"/student/spelling_games/hangman?spelling_words=#{Enum.join(@spelling_words, ",")}" } class="text-sm text-accent underline">Debug: Hangman</a>
        <a href={"/student/spelling_games/flashcards?spelling_words=#{Enum.join(@spelling_words, ",")}" } class="ml-4 text-sm text-accent underline">Debug: Flashcards</a>
        <a href={"/student/spelling_games/matching?spelling_words=#{Enum.join(@spelling_words, ",")}" } class="ml-4 text-sm text-accent underline">Debug: Matching</a>
        <a href={"/student/spelling_games/word_search?spelling_words=#{Enum.join(@spelling_words, ",")}" } class="ml-4 text-sm text-accent underline">Debug: Word Search</a>
        <a href={"/student/spelling_games/crossword?spelling_words=#{Enum.join(@spelling_words, ",")}" } class="ml-4 text-sm text-accent underline">Debug: Crossword</a>
        <a href={"/student/spelling_games/unscramble?spelling_words=#{Enum.join(@spelling_words, ",")}" } class="ml-4 text-sm text-accent underline">Debug: Unscramble</a>
        <a href={"/student/spelling_games/catch_it?spelling_words=#{Enum.join(@spelling_words, ",")}" } class="ml-4 text-sm text-accent underline">Debug: Catch It</a>
      </div>
    </div> 
    """
  end

  def handle_event("start_review", _value, socket) do
    if socket.assigns.welcome_timer do
      Process.cancel_timer(socket.assigns.welcome_timer)
    end
    send(self(), :start_review)
    {:noreply, assign(socket, welcome_timer: nil)}
  end

  def handle_event("prev_word", _value, socket) do
    # Cancel timers when manually navigating
    socket = cancel_timers(socket)
    
    current_index = max(0, socket.assigns.current_index - 1)
    current_word = Enum.at(socket.assigns.spelling_words, current_index)

    {:noreply, assign(socket, current_index: current_index, current_word: current_word, current_text: current_word)}
  end

  def handle_event("next_word", _value, socket) do
    # Cancel timers when manually navigating
    socket = cancel_timers(socket)
    socket = advance_word(socket)
    {:noreply, socket}
  end

  def handle_event("toggle_pause", _value, socket) do
    if socket.assigns.auto_advance do
      # Pause
      socket = cancel_timers(socket)
      {:noreply, assign(socket, auto_advance: false)}
    else
      # Play
      socket = schedule_advance(socket)
      {:noreply, assign(socket, auto_advance: true)}
    end
  end

  def handle_event("restart", _value, socket) do
    # Restart the review session
    if socket.assigns.timer_ref do
      Process.cancel_timer(socket.assigns.timer_ref)
    end
    socket = socket
      |> assign(:current_index, 0)
      |> assign(:current_word, List.first(socket.assigns.spelling_words))
      |> assign(:current_text, List.first(socket.assigns.spelling_words))
      |> assign(:view_state, :review)
      |> assign(:auto_advance, true)
      |> assign(:timer_ref, nil)
      |> schedule_advance()

    {:noreply, socket}
  end

  def handle_event("start_game", _params, socket) do
    game = socket.assigns.selected_game
    
    # Check if clues are ready
    if game in ["crossword", "flashcards", "catch_it"] do
      case socket.assigns.clue_generation_status do
        :ready -> 
          # Clues ready, store in cache and navigate with cache key
          cache_key = ClueCache.put(socket.assigns.student_id, socket.assigns.clues)
          query_params = %{
            "spelling_words" => Enum.join(socket.assigns.spelling_words, ","),
            "clue_cache_key" => cache_key
          }
          words_param = URI.encode_query(query_params)
          
          {:noreply, push_navigate(socket, to: "/student/spelling_games/#{game}?#{words_param}")}
        
        :generating ->
          # Still generating, stay on this page with loading indicator
          {:noreply, socket}
        
        :failed ->
          # Failed, pick fallback
          fallback = GameSelector.select_fallback_game(socket.assigns.game_history)
          query_params = %{"spelling_words" => Enum.join(socket.assigns.spelling_words, ",")}
          words_param = URI.encode_query(query_params)
          
          socket = put_flash(socket, :error, "#{game} generation failed, playing #{fallback} instead")
          {:noreply, push_navigate(socket, to: "/student/spelling_games/#{fallback}?#{words_param}")}
        
        _ ->
          # Not started, shouldn't happen but handle it
          {:noreply, socket}
      end
    else
      # Non-clue-based game, navigate immediately
      query_params = %{"spelling_words" => Enum.join(socket.assigns.spelling_words, ",")}
      words_param = URI.encode_query(query_params)
      
      {:noreply, push_navigate(socket, to: "/student/spelling_games/#{game}?#{words_param}")}
    end
  end

  def handle_info(:generate_clues, socket) do
    # Start async task to generate clues
    parent = self()
    spelling_words = socket.assigns.spelling_words
    user_progress = socket.assigns.user_progress
    game = socket.assigns.selected_game
    
    Task.start(fn ->
      result = case game do
        "crossword" -> 
          ElixirAndrewWeb.Student.SpellingGames.Crossword.CrosswordGenerator.get_crossword_clues(
            spelling_words,
            user_progress
          )
        "flashcards" -> 
          ElixirAndrewWeb.Student.SpellingGames.FlashcardsLive.get_definitions(
            spelling_words,
            user_progress
          )
        "catch_it" ->
          ElixirAndrewWeb.Student.SpellingGames.CatchItLive.get_definitions(
            spelling_words,
            user_progress
          )
        _ -> {:error, "Unknown game type: #{game}"}
      end
      
      send(parent, {:clues_ready, result})
    end)
    
    {:noreply, assign(socket, :clue_generation_status, :generating)}
  end
  
  def handle_info({:clues_ready, {:ok, clues}}, socket) do
    IO.inspect(clues, label: "Clues generated successfully")
    
    socket = assign(socket, clues: clues, clue_generation_status: :ready)
      
    # Auto-navigate if user is on completed view (waiting to play)
    if socket.assigns.view_state == :completed and socket.assigns.selected_game in ["crossword", "flashcards", "catch_it"] do
      cache_key = ClueCache.put(socket.assigns.student_id, clues)
      query_params = %{
        "spelling_words" => Enum.join(socket.assigns.spelling_words, ","),
        "clue_cache_key" => cache_key
      }
      words_param = URI.encode_query(query_params)
      
      {:noreply, push_navigate(socket, to: "/student/spelling_games/#{socket.assigns.selected_game}?#{words_param}")}
    else
      {:noreply, socket}
    end
  end
  
  def handle_info({:clues_ready, {:error, reason}}, socket) do
    IO.inspect(reason, label: "Failed to generate clues")
    
    # Select a new game that doesn't require AI generation
    fallback_game = GameSelector.select_fallback_game(socket.assigns.game_history)
    
    {:noreply, assign(socket, 
      clue_generation_status: :failed,
      selected_game: fallback_game
    )}
  end

  def handle_info(:start_review, socket) do
    # Transition to review state
    socket = socket
      |> advance_word()
      |> assign(:view_state, :review)
      |> assign(:current_text, socket.assigns.current_word)
    
    {:noreply, socket}
  end

  def handle_info(:auto_advance, socket) do
    # Check if we're at the last word before advancing
    if socket.assigns.current_index >= length(socket.assigns.spelling_words) - 1 do
      # Already on last word, transition to completed
      socket = set_completed(socket)
      {:noreply, socket}
    else
      # Advance to next word
      socket = advance_word(socket)
      
      # Schedule next advance if not at the last word now
      if socket.assigns.current_index < length(socket.assigns.spelling_words) - 1 and socket.assigns.auto_advance do
        socket = schedule_advance(socket)
        {:noreply, socket}
      else
        # Just moved to the last word, schedule timer for it
        socket = schedule_advance(socket)
        {:noreply, socket}
      end
    end
  end

  def handle_info(:update_timer_progress, socket) do
    new_progress = min(socket.assigns.timer_progress + 2, 100) # Increment by 2% (50 updates * 2% = 100%)
    
    socket = assign(socket, timer_progress: new_progress)
    
    # Schedule next update if not at 100%
    if new_progress < 100 and socket.assigns.auto_advance do
      progress_timer_ref = Process.send_after(self(), :update_timer_progress, 80) # 80ms * 50 = 4000ms
      {:noreply, assign(socket, progress_timer_ref: progress_timer_ref)}
    else
      {:noreply, socket}
    end
  end

  def schedule_advance(socket) do
    # Cancel existing timers
    if socket.assigns.timer_ref do
      Process.cancel_timer(socket.assigns.timer_ref)
    end
    if socket.assigns.progress_timer_ref do
      Process.cancel_timer(socket.assigns.progress_timer_ref)
    end
    
    # Schedule auto-advance
    timer_ref = Process.send_after(self(), :auto_advance, 4000) # 4 seconds
    
    # Reset and start progress timer
    progress_timer_ref = Process.send_after(self(), :update_timer_progress, 80) # Start updating progress
    
    socket
    |> assign(timer_ref: timer_ref)
    |> assign(progress_timer_ref: progress_timer_ref)
    |> assign(timer_progress: 0)
  end

  defp cancel_timers(socket) do
    if socket.assigns.timer_ref do
      Process.cancel_timer(socket.assigns.timer_ref)
    end
    if socket.assigns.progress_timer_ref do
      Process.cancel_timer(socket.assigns.progress_timer_ref)
    end
    assign(socket, timer_ref: nil, progress_timer_ref: nil)
  end

  defp advance_word(socket) do
    current_index = socket.assigns.current_index + 1
    
    # Check if we've gone past the last word
    if current_index >= length(socket.assigns.spelling_words) do
      set_completed(socket)
    else
      current_word = Enum.at(socket.assigns.spelling_words, current_index)
      socket = assign(socket, current_index: current_index, current_word: current_word, current_text: current_word)
      
      # Schedule advance if auto_advance is on and we're not on the last word
      if socket.assigns.auto_advance and current_index <= length(socket.assigns.spelling_words) - 1 do
        schedule_advance(socket)
      else
        socket
      end  
    end
  end

  defp set_completed(socket) do
    cancel_timers(socket)
    assign(socket, auto_advance: false, current_text: "Great job! You've reviewed all your words. You can now try a spelling game.", view_state: :completed)
  end

end