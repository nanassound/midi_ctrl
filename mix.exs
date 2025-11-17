defmodule MIDICtrl.MixProject do
  use Mix.Project

  def project do
    [
      app: :midi_ctrl,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        midi_ctrl: [
          include_executables_for: [:unix, :windows],
          applications: [
            runtime_tools: :permanent,
            midi_ctrl: :permanent
          ],
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MIDICtrl.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:midiex, "~> 0.6.3"},
      {:bandit, "~> 1.8"},
      {:plug, "~> 1.18"},
      {:jason, "~> 1.4"}
    ]
  end
end
