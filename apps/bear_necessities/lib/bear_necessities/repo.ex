defmodule BearNecessities.Repo do
  use Ecto.Repo,
    otp_app: :bear_necessities,
    adapter: Ecto.Adapters.Postgres
end
