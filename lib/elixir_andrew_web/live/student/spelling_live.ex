defmodule ElixirAndrewWeb.Student.SpellingLive do
  use ElixirAndrewWeb, :live_view

  def mount(_params, _session, socket) do
    student_id = socket.assigns.current_user.id
    spelling_words =
      case ElixirAndrew.ClassSession.get_last_class_with_spelling(student_id) do
        %{spelling_words: words} -> words
        _ -> []
      end

    {:ok, assign(socket, student_id: student_id, spelling_words: spelling_words)}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto border border-solid border-primary border-4 p-6 w-full">
      <h2 class="text-3xl text-primary font-bold mb-4">Time to review your spelling words</h2>
      <p class="mb-6">Here are your spelling words from your last lesson. Practice saying and writing them before you start the games!</p>
      <ul class="list-disc list-inside mb-6">
        <%= for word <- @spelling_words do %>
          <li class="text-xl"><%= word %></li>
        <% end %>
      </ul>
      <%!-- Spelling review area before continuing to the spelling games --%>
    </div> 
    """
  end
end