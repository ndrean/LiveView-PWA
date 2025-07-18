defmodule LiveviewPwa.MixProject do
  use Mix.Project

  def project do
    [
      app: :liveview_pwa,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveviewPwa.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_ecto, "~> 4.6"},
      {:bandit, "~> 1.6"},
      {:req, "~> 0.5.8"},
      {:nimble_csv, "~> 1.2"},
      {:exqlite, "0.30.1"},
      {:ecto_sqlite3, "~> 0.19.0"},
      {:ecto_watch, "~> 0.13.2"},
      {:ecto_psql_extras, "~> 0.6"},
      {:ecto_sqlite3_extras, "~> 1.2.0"},
      {:postgrex, "~> 0.20.0"},
      {:electric, "~> 1.0.13"},
      {:phoenix_sync, "~> 0.4.3"},
      {:ua_parser, "~> 1.9.3"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false, depth: 1},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.1", only: [:dev, :test], runtime: false},
      {:credo_contrib, "~> 0.2", only: [:dev, :test], runtime: false},
      {:quokka, "~> 2.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:tidewave, "~> 0.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets pnpm i"],
      "assets.deploy": [
        # https://vite.dev/config/
        "cmd --cd assets vite build --config vite.config.js",
        "phx.digest"
      ],
      qa: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        # "sobelow --skip Config",
        # "credo --strict",
        "dialyzer"
      ]
    ]
  end
end
