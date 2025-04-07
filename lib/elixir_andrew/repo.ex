defmodule ElixirAndrew.Repo do
  use Ecto.Repo,
    otp_app: :elixir_andrew,
    adapter: Ecto.Adapters.Postgres
end
