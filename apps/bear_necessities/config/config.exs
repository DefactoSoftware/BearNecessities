# Since configuration is shared in umbrella projects, this file
# should only configure the :bear_necessities application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

config :bear_necessities,
  ecto_repos: [BearNecessities.Repo]

import_config "#{Mix.env()}.exs"
