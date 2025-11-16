# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MIDICtrl is an HTTP-based MCP (Model Context Protocol) server that enables LLMs to control and interact with MIDI devices. Built with Elixir, it uses Bandit as the HTTP server and implements the MCP JSON-RPC protocol directly to expose MIDI functionality as MCP tools.

## Development Commands

### Dependencies
```bash
mix deps.get              # Install dependencies
```

### Testing
```bash
mix test                  # Run all tests
mix test test/path_test.exs  # Run a specific test file
mix test test/path_test.exs:42  # Run test at specific line
```

### Code Formatting
```bash
mix format                # Format all Elixir files
mix format --check-formatted  # Check if files are formatted
```

### Building
```bash
mix compile               # Compile the project
```

### Running the MCP Server
```bash
elixir run_mcp.exs        # Run the HTTP server (listens on port 3000)
PORT=8080 elixir run_mcp.exs  # Run on custom port
```

## Architecture

### Core Structure

The project implements an HTTP-based MCP server with three main modules:

- **`MIDICtrl.Router`** (lib/midi_ctrl/router.ex): The main HTTP router using Plug. Handles MCP JSON-RPC requests at `/mcp` endpoint and implements the MCP protocol methods (initialize, tools/list, tools/call). This is the entry point for the MCP server.

- **`MIDIOps`** (lib/midi_ops.ex): Contains MIDI operation implementations. Currently provides `list_ports/0` which queries available MIDI ports using the `Midiex` library and formats them as a string.

- **`run_mcp.exs`**: Startup script that loads dependencies, starts the Bandit HTTP server, and keeps the server running.

### Key Dependencies

- **midiex** (~> 0.6.3): Elixir wrapper for MIDI functionality, providing access to MIDI ports and devices
- **bandit** (~> 1.8): Fast HTTP server built on Thousand Island
- **plug** (~> 1.18): Composable web middleware
- **jason** (~> 1.4): JSON encoding/decoding

### MCP Protocol Implementation

The server implements the MCP protocol via HTTP/JSON-RPC:

1. **HTTP Transport**: Uses Bandit HTTP server with Plug router
2. **JSON-RPC**: Handles MCP methods as JSON-RPC 2.0 requests
3. **MCP Methods Supported**:
   - `initialize`: Returns server capabilities and protocol version
   - `notifications/initialized`: Acknowledges initialization
   - `tools/list`: Returns available tools
   - `tools/call`: Executes tool requests
   - `notifications/cancelled`: Handles cancellations

### Claude Desktop Integration

The server integrates with Claude Desktop via `mcp-remote`:

```json
{
  "mcpServers": {
    "midi_ctrl": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://localhost:3000/mcp"]
    }
  }
}
```

### Adding New MCP Tools

To add new MCP tools:

1. Add tool definition in `MIDICtrl.Router.handle_mcp_method("tools/list", ...)` (lib/midi_ctrl/router.ex:46)
2. Implement tool execution in `MIDICtrl.Router.handle_mcp_method("tools/call", ...)` (lib/midi_ctrl/router.ex:65)
3. Add operation logic in `MIDIOps` or create new operation modules

### MIDI Port Information

MIDI ports have the following attributes:
- `name`: Human-readable port name
- `direction`: `:input` or `:output`
- `num`: Port number identifier
