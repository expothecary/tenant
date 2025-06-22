defmodule Tenant.Mixfile do
  use Mix.Project

  @source_url "https://github.com/exliir-apothecary/tenant"
  @version "2.0.0"

  def project do
    [
      app: :tenant,
      version: @version,
      elixir: "~> 1.7",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps(),
      docs: docs(),
      name: "Tenant"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:decimal, "~> 2.0"},
      {:ecto_sql, "~> 3.0"},

      # optional dependencies
      {:myxql, ">= 0.3.0", optional: true},
      {:plug, "~> 1.6", optional: true},
      {:postgrex, ">= 0.15.0", optional: true},

      # dev support
      {:credo, "~> 1.0", only: [:test, :dev], optional: true, runtime: false},

      # testing support
      {:excoveralls, "~> 0.0", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},

      # docs support
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false},
      {:inch_ex, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "db.migrate": ["ecto.migrate", "tenant.migrate"],
      test: ["test.reset", "ecto.migrate", "test"],
      "test.reset": ["ecto.drop", "ecto.create", "db.migrate"],
      "test.cover": &run_default_coverage/1,
      "test.cover.html": &run_html_coverage/1
    ]
  end

  defp package do
    [
      name: :tenant3,
      description: "Build multitenant applications on top of Ecto.",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Kelvin Stinghen"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp preferred_cli_env do
    [
      docs: :docs,
      "hex.publish": :docs,
      coveralls: :test,
      "coveralls.travis": :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "test.reset": :test
    ]
  end

  defp run_default_coverage(args), do: run_coverage("coveralls", args)
  defp run_html_coverage(args), do: run_coverage("coveralls.html", args)

  defp run_coverage(task, args) do
    {_, res} =
      System.cmd(
        "mix",
        [task | args],
        into: IO.binstream(:stdio, :line),
        env: [{"MIX_ENV", "test"}]
      )

    if res > 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end
