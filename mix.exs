defmodule MSF.MixProject do
  use Mix.Project

  def project do
    [
      app:              :msf_format,
      version:          "0.1.0",
      elixir:           "~> 1.11",
      start_permanent:  Mix.env() == :prod,
      deps:             deps(),
      description:      description(),
      package:          package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  def package do
    [
      maintainers: ["Warren Kenny"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/wrren/msf.ex"}
    ]
  end

  def description do
    """
    Provides functions for reading Multi-Stream Format (MSF) files, which are the backing format for
    file types such as PDB.
    """
  end
end
