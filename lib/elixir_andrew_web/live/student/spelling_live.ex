defmodule ElixirAndrewWeb.Student.SpellingLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    student_id = socket.assigns.current_user.id
    spelling_words =
      case ElixirAndrew.ClassSession.get_last_class_with_spelling(student_id) do
        %{spelling_words: words} -> words
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
            <p class="self-center mb-8"> <%= @current_text %> </p>
            <button phx-click="start_review" class="btn-primary btn-effect" > Okay!</button>
          </div>
      
        <% :review -> %>
          <div class="flex flex-col flex-1 items-center space-x-4 my-4 border border-solid border-2 rounded-xl border-primary p-4">
            <div class="flex flex-col flex-1"> 
              <div class="flex flex-col items-center">
                <p class="" ><%= @current_index + 1 %> / <%= length(@spelling_words) %></p>
                <progress class="progress progress-primary rounded-full h-4 w-56" value={@current_index + 1} max={length(@spelling_words)}></progress>
              </div>
              <div class="flex flex-col flex-1 justify-center items-center">
                <p class="text-xl font-bold"><%= @current_text %></p>
              </div>
            </div>
            <div class="flex my-4 border border-solid border-2 border-primary p-4">
              <button phx-click="prev_word" class="btn-primary btn-effect" disabled={@current_index == 0}>Back</button>
              <button phx-click="toggle_pause" class="btn-primary btn-effect"><%= if @auto_advance, do: "Pause", else: "Play" %></button>
              <button phx-click="next_word" class="btn-primary btn-effect">Next</button>
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
              <button phx-click="restart" class="flex-1 px-4 py-2 bg-secondary text-white">Review Again</button>
              <button phx-click="start_game" class="flex-4 px-4 py-2 bg-accent text-white">Start Spelling Game</button>
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
    current_index = max(0, socket.assigns.current_index - 1)
    current_word = Enum.at(socket.assigns.spelling_words, current_index)

    {:noreply, assign(socket, current_index: current_index, current_word: current_word, current_text: current_word)}
  end

  def handle_event("next_word", _value, socket) do
    socket = advance_word(socket)
    {:noreply, socket}
  end

  def handle_event("toggle_pause", _value, socket) do
    if socket.assigns.auto_advance do
      # Pause
      if socket.assigns.timer_ref do
        Process.cancel_timer(socket.assigns.timer_ref)
      end
      {:noreply, assign(socket, auto_advance: false, timer_ref: nil)}
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

    {:noreply, socket}
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
    socket = advance_word(socket)
    if socket.assigns.current_index < length(socket.assigns.spelling_words) - 1 and socket.assigns.auto_advance do
      socket = schedule_advance(socket)
      {:noreply, socket}
    else
      {:noreply, assign(socket, auto_advance: false, timer_ref: nil)}
    end
  end

  def schedule_advance(socket) do
    if socket.assigns.timer_ref do
      Process.cancel_timer(socket.assigns.timer_ref)
    end
    timer_ref = Process.send_after(self(), :auto_advance, 5000) # 5 seconds
    assign(socket, timer_ref: timer_ref)
  end

  defp advance_word(socket) do
    if socket.assigns.current_index < length(socket.assigns.spelling_words) - 1 do
      current_index = socket.assigns.current_index + 1
      current_word = Enum.at(socket.assigns.spelling_words, current_index)
      socket = assign(socket, current_index: current_index, current_word: current_word, current_text: current_word)
      if socket.assigns.auto_advance do
        schedule_advance(socket)
      else
        assign(socket, timer_ref: nil)
      end
    else
      # Reached the end of the words
      if socket.assigns.timer_ref do
        Process.cancel_timer(socket.assigns.timer_ref)
      end
      assign(socket, auto_advance: false, timer_ref: nil, current_text: "Great job! You've reviewed all your words. You can now try a spelling game.", view_state: :completed)
    end
  end

end