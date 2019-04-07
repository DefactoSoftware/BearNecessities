# Since configuration is shared in umbrella projects, this file
# should only configure the :bear_necessities application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# Configure your database
config :bear_necessities, BearNecessities.Repo,
  username: "postgres",
  password: "postgres",
  database: "bear_necessities_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
