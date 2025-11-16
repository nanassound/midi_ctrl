#!/usr/bin/env elixir

# Install dependencies
Mix.install([
  {:midiex, "~> 0.6.3"},
  {:bandit, "~> 1.8"},
  {:plug, "~> 1.18"},
  {:jason, "~> 1.4"}
])

# Load the application modules
Code.require_file("lib/midi_ops.ex", __DIR__)
Code.require_file("lib/midi_ctrl/router.ex", __DIR__)

# Configure the port (default to 3000)
port = String.to_integer(System.get_env("PORT") || "3000")

# Start the Bandit server
children = [
  {Bandit, plug: MIDICtrl.Router, scheme: :http, port: port}
]

# Start the supervisor
case Supervisor.start_link(children, strategy: :one_for_one) do
  {:ok, _pid} ->
    IO.puts(:stderr, "")
    IO.puts(:stderr, "✓ MIDI Ctrl MCP Server started successfully!")
    IO.puts(:stderr, "  - HTTP Server: http://localhost:#{port}")
    IO.puts(:stderr, "  - MCP Endpoint: http://localhost:#{port}/mcp")
    IO.puts(:stderr, "  - Health Check: http://localhost:#{port}/")
    IO.puts(:stderr, "")
    IO.puts(:stderr, "Press Ctrl+C to stop the server")
    IO.puts(:stderr, "")

    # Keep the process running
    Process.sleep(:infinity)

  {:error, reason} ->
    IO.puts(:stderr, "Failed to start MCP server: #{inspect(reason)}")
    System.halt(1)
end
