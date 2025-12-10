defmodule ElixirAndrewWeb.Student.StudentHomeLive do
  use ElixirAndrewWeb, :live_view
  import ElixirAndrewWeb.BoxComponents

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    theme = current_user.theme || "theme-default"
    socket = assign(socket, current_user: current_user, student_id: current_user.id, theme: theme)
    {:ok, socket} 
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-full overflow-hidden">
      <div class="text-center">
        <p class="text-3xl"><%= @current_user.first_name %> <%= @current_user.last_name %> </p>
        <p class="text-accent">Welcome to your student home page! </p>
      </div>

      <p class="text-center">
        Here you can find lessons and homework.
      </p>

      <div class="mt-6 flex flex-col justify-center">
        <div class="block-wrapper">
          <.floating_block_link to={~p"/student/#{@student_id}/communication"} class="rectangle small">
            My Homework
          </.floating_block_link>
        </div>

        <div class="flex items-center gap-4 md:gap-8 lg:gap-24 mt-10 px-4 md:px-12">
          <div class="block-wrapper">
            <.floating_block_link to={~p"/student/spelling_review"} class="rectangle small">
              Spelling
            </.floating_block_link>
          </div>
          
          <div class="block-wrapper">
            <.floating_block_link to={~p"/student/home"} class="rectangle small">
              Chat
            </.floating_block_link>
          </div>
         </div>
      </div>

    </div>
    """
  end
end