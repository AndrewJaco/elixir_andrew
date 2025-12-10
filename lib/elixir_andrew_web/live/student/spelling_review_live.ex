defmodule ElixirAndrewWeb.Student.SpellingReviewLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    student_id = socket.assigns.current_user.id
    spelling_words =
      case ElixirAndrew.ClassSession.get_last_class_with_spelling(student_id) do
        %{spelling_words: words} -> words
        _ -> []
      end
    user_progress = ElixirAndrew.Progress.get_user_progress(student_id)
    game_history = if user_progress, do: user_progress.game || [], else: []
    
    IO.inspect(user_progress, label: "User progress for #{student_id}")
    IO.inspect(game_history, label: "Game history")

      socket = socket
      |> assign(:student_id, student_id)
      |> assign(:spelling_words, spelling_words)
      |> assign(:current_index, -1)
      |> assign(:current_word, List.first(spelling_words))
      |> assign(:current_text, "Review first!")
      |> assign(:game_history, game_history)
      |> assign(:timer_ref, nil)
      |> assign(:auto_advance, true)
      |> assign(:view_state, :welcome)
      |> assign(:timer_progress, 0)
      |> assign(:progress_timer_ref, nil)

      welcome_timer = Process.send_after(self(), :start_review, 5000)
      socket = assign(socket, :welcome_timer, welcome_timer)

      {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col border border-solid border-accent border-4 p-8 m-4">
      <%= case @view_state do %>
        <% :welcome -> %>
          <h2 class="self-center text-3xl text-dark font-bold mb-4">Time to review your spelling words</h2>
          <div class="flex flex-col flex-1 items-center justify-center my-4 border border-solid border-2 rounded-xl border-primary p-4">
            <p class="mb-8 text-2xl font-semibold"> <%= @current_text %> </p>
            <button phx-click="start_review" class="btn-primary btn-effect" > Okay!</button>
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
                <button phx-click="prev_word" class="btn-primary btn-effect flex items-center justify-center" disabled={@current_index == 0}>
                  <.icon name="hero-chevron-left-solid" class="h-5 w-5"/>
                </button>
                <button phx-click="toggle_pause" class="btn-primary btn-effect flex items-center justify-center">
                  <%= if @auto_advance do %>
                    <.icon name="hero-pause-solid" class="h-5 w-5"/>
                  <% else %>
                    <.icon name="hero-play-solid" class="h-5 w-5"/>
                  <% end %>
                </button>
                <button phx-click="next_word" class="btn-primary btn-effect flex items-center justify-center">
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
              <button phx-click="start_game" class="flex-4 px-4 py-2 bg-accent text-white gem-btn accent">Start Spelling Game</button>
            </div>
          </div>
      <% end %>
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
    game_type = ElixirAndrew.SpellingGames.select_game(
      socket.assigns.game_history,
      "spelling"
    )
    
    {:noreply, 
      push_navigate(socket, 
        to: "/student/spelling-games/#{game_type}"
      )
    }
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