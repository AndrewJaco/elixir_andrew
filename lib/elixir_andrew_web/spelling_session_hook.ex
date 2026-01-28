defmodule ElixirAndrewWeb.SpellingSessionHook do
  import Phoenix.Component

  def on_mount(:default, params, _session, socket) do
    # If spelling_words already assigned (e.g., from navigation within spelling session),
    # keep them instead of reloading
    spelling_words = if socket.assigns[:spelling_words] do
      socket.assigns.spelling_words
    else
      load_spelling_words(socket.assigns[:current_user], params)
    end
    
    {:cont, assign(socket, :spelling_words, spelling_words)}
  end

  defp load_spelling_words(nil, _params), do: []

  defp load_spelling_words(%{role: "student"} = user, _params) do
    # For students, get their last class session's spelling words
    case ElixirAndrew.ClassSession.get_last_class_with_spelling(user.id) do
      %{spelling_words: words} -> words
      _ -> []
    end
  end

  defp load_spelling_words(%{role: role}, params) when role in ["admin", "teacher"] do
    # For admin/teacher, check if custom spelling words are provided via params
    case params["spelling_words"] do
      nil -> get_default_teacher_words()
      words when is_binary(words) -> 
        words
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
      words when is_list(words) -> words
    end
  end

  defp load_spelling_words(_user, _params), do: []

  # Default words for teachers/admins to test with
  defp get_default_teacher_words do
    ["apple", "banana", "orange", "grape", "melon", "peach", "plum", "cherry"]
  end
end
