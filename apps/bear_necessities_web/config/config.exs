# Since configuration is shared in umbrella projects, this file
# should only configure the :bear_necessities_web application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# General application configuration
config :bear_necessities_web,
  ecto_repos: [BearNecessities.Repo],
  generators: [context_app: :bear_necessities]

# Configures the endpoint
config :bear_necessities_web, BearNecessitiesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "XGyIQiCWhwimCTtX1G470XJdDMgNqYBgjETuYNYeqbYLHj1ATH2IaTtM2Z5iF8JN",
  render_errors: [view: BearNecessitiesWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: BearNecessitiesWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
