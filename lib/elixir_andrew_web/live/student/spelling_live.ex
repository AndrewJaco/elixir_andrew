defmodule ElixirAndrewWeb.Student.SpellingLive do
  use ElixirAndrewWeb, :live_view
  def mount(_params, session, socket) do
    
    current_user = 
      case Map.get(session, "user_token") do
        nil -> nil
        user_token -> ElixirAndrew.Accounts.get_user_by_session_token(user_token)
      end
    if current_user == nil do
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    else
      theme = current_user.theme || "theme-default"
      socket = assign(socket, current_user: current_user, theme: theme, student_id: current_user.id, spelling_words: ["eat", "sleep", "play", "read", "write", "do"])
      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto border border-solid border-primary border-4 p-6 w-full">
      <h2 class="text-3xl text-primary font-bold mb-4">Time to review your spelling words</h2>
      <%!-- Spelling review area before continuing to the spelling games --%>
    </div>
    """
  end
end