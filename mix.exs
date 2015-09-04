defmodule Cthulhu.Mixfile do
  use Mix.Project

  def project do
    [app: :cthulhu,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison],
              mod: {Cthulhu, []}]
  end

  defp deps do
    [{:httpoison, "~> 0.7.2"}]
  end
end
