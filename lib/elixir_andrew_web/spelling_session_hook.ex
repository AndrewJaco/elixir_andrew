defmodule ElixirAndrewWeb.SpellingSessionHook do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    # Load spelling words once for the entire spelling session
    spelling_words = if socket.assigns[:current_user] do
      case ElixirAndrew.ClassSession.get_last_class_with_spelling(socket.assigns.current_user.id) do
        %{spelling_words: words} -> words
        _ -> []
      end
    else
      []
    end
    
    {:cont, assign(socket, :spelling_words, spelling_words)}
  end
end
