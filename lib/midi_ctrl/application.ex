defmodule MIDICtrl.Application do
  @moduledoc """
  The MIDICtrl Application.

  This module starts the HTTP server when running as a release.
  For development, use run_mcp.exs instead.
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Configure the port (default to 3000)
    port = String.to_integer(System.get_env("PORT") || "3000")

    IO.puts(:stderr, "")
    IO.puts(:stderr, "✓ MIDI Ctrl MCP Server starting...")
    IO.puts(:stderr, "  - HTTP Server: http://localhost:#{port}")
    IO.puts(:stderr, "  - MCP Endpoint: http://localhost:#{port}/mcp")
    IO.puts(:stderr, "  - Health Check: http://localhost:#{port}/")
    IO.puts(:stderr, "")

    # Define the child processes to supervise
    children = [
      {Bandit, plug: MIDICtrl.Router, scheme: :http, port: port}
    ]

    # Start the supervisor with the children
    opts = [strategy: :one_for_one, name: MIDICtrl.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
