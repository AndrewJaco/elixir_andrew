defmodule ElixirAndrewWeb.Student.SpellingGames.Crossword.ClueCache do
  @moduledoc """
  Temporary cache for pre-generated crossword clues to avoid duplicate AI calls.
  Clues expire after 5 minutes.
  """
  use Agent

  @ttl 300_000  # 5 minutes

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc "Store clues with a unique key, returns the key"
  def put(student_id, clues) do
    key = generate_key(student_id)
    expires_at = System.monotonic_time(:millisecond) + @ttl
    
    Agent.update(__MODULE__, fn state ->
      Map.put(state, key, {clues, expires_at})
    end)
    
    key
  end

  @doc "Retrieve and delete clues by key"
  def pop(key) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Map.get(state, key) do
        {clues, expires_at} ->
          if System.monotonic_time(:millisecond) < expires_at do
            {clues, Map.delete(state, key)}
          else
            # Expired
            {nil, Map.delete(state, key)}
          end
        nil ->
          {nil, state}
      end
    end)
  end

  @doc "Cleanup expired entries (called periodically)"
  def cleanup do
    now = System.monotonic_time(:millisecond)
    
    Agent.update(__MODULE__, fn state ->
      state
      |> Enum.reject(fn {_key, {_clues, expires_at}} -> expires_at < now end)
      |> Map.new()
    end)
  end

  defp generate_key(student_id) do
    "#{student_id}_#{System.unique_integer([:positive])}"
  end
end
