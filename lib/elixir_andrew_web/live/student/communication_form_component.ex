defmodule ElixirAndrewWeb.Student.CommunicationFormComponent do
  use ElixirAndrewWeb, :live_component
  alias ElixirAndrew.ClassSession
  @doc """
  Renders a single class session form component.
  """
  def mount(socket) do
    {:ok, socket}
  end
  
  def update(assigns, socket) do
    session = assigns[:session] || %ClassSession{}
    
    is_new = Map.get(assigns, :is_new)
    
    session = if is_new && is_nil(session.date) do
      %{session | date: Date.utc_today()}
    else
      session
    end

    changeset = ClassSession.change_class_session(session)

    socket = socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end
  
  def render(assigns) do
    ~H"""
    <div class={[
    "py-4 px-8 border-2 rounded-xl w-full shadow-md flex w-fit",
    @is_new && "border-accent mb-4" || "border-primary",
    ]}>
      <.form 
        for={@form}
        id={"communication_form-#{@id}"}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
        >
        <div class="flex flex-col w-[600px]">
          <%= if @is_new do %>
            <div class="relative cursor-pointer" phx-hook="DatePicker" id={"date-picker-#{@id}"}>
              <.input 
                type="date" 
                name="date"
                field={@form[:date]}
                class="mb-2 p-2 border border-primary rounded-md"
                placeholder="Select Date"
                id={"date-input-#{@id}"}
                readonly={not @is_new}
                />
              <div class="absolute inset-0" id={"date-overlay-#{@id}"}></div>
            </div>
          <% else %>
            <input type="hidden" name="date" value={@form[:date].value} id={"date-input-#{@id}"}/>
            <div class="mb-2 p-2">
              <p><%= format_date(@form[:date].value) %></p> 
            </div>
          <% end %>
          <div class="mt-2">
            <.label for={"lesson-input-#{@id}"}>Today's Lesson</.label>
            <.input
              type="textarea" 
              name="lesson"
              field={@form[:lesson]}
              class="mb-2 p-2 border border-primary rounded-md"
              placeholder="Lesson"
              readonly={not @is_new}
              id={"lesson-input-#{@id}"}
              />
          </div>
          <div class="mt-1">
            <.label for={"homework-input-#{@id}"}>Homework</.label>
            <.input
              type="textarea" 
              name="homework"
              field={@form[:homework]}
              class="mb-2 p-2 border border-primary rounded-md"
              placeholder="Homework"
              readonly={not @is_new}
              id={"homework-input-#{@id}"}
              />
          </div>
          <div class="mt-2">
            <.label for={"spelling-words-input-#{@id}"} >Spelling Words</.label>
            <.input
              type="text" 
              name="spelling_words"
              field={@form[:spelling_words]}
              class="mb-2 p-2 border border-primary rounded-md"
              placeholder="Spelling Words (comma separated)"
              readonly={not @is_new}
              id={"spelling-words-input-#{@id}"}
              />
          </div>
          <%= if @is_new do %>
          <div class="flex gap-1 mt-4">
            <button class="bg-alert text-white py-2 px-4 rounded-md" phx-click="cancel-new-session" phx-target={@myself}>Cancel</button>
            <button class="flex-1 bg-secondary rounded-md text-white" phx-click="save" phx-target={@myself}>
              Save Session
            </button>
          </div>
          <% end %>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("validate", params, socket) do
    params = handle_spelling_words(params)

    params = Map.put(params, "student_id", socket.assigns.session.student_id)

    changeset = 
      socket.assigns.session
      |> ClassSession.change_class_session(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", params, socket) do
    params = handle_spelling_words(params)
    params = Map.put(params, "student_id", socket.assigns.session.student_id)

    if socket.assigns.session.id == nil do
      case ClassSession.create_class_session(params) do
        {:ok, saved_session} ->
          if socket.assigns[:is_new] do
            # socket = assign(socket, is_new: false)
            send(self(), {:session_created, saved_session})
          end
          {:noreply, 
            socket
            |> put_flash(:info, "Class created successfully.")
            |> assign(session: saved_session)
            |> assign(form: to_form(ClassSession.change_class_session(saved_session)))}

        {:error, changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      case ClassSession.update_class_session(socket.assigns.session, params) do
      {:ok, saved_session} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Session updated successfully")
         |> assign(session: saved_session)
         |> assign(form: to_form(ClassSession.change_class_session(saved_session)))}
        
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  def handle_event("cancel-new-session", _params, socket) do
    send(self(), {:cancel_new_session})
    
    {:noreply, socket}
  end

  defp handle_spelling_words(params) do
    case params["spelling_words"] do
      nil -> params
      words ->
        words_list = String.split(words, ",")
        Map.put(params, "spelling_words", words_list)
    end
  end

  defp format_date(nil), do: ""
  defp format_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%B %d, %Y")
      {:error, _} -> date_string  # Fallback to the original string
    end
  end
  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end