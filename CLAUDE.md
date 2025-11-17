# CLAUDE.md

**Developer & Contributor Guide for Claude Code**

This file provides guidance to Claude Code (claude.ai/code) and human contributors when working with code in this repository.

## Project Overview

MIDICtrl is an HTTP-based MCP (Model Context Protocol) server that enables LLMs to control and interact with MIDI devices. Built with Elixir, it uses Bandit as the HTTP server and implements the MCP JSON-RPC protocol directly to expose MIDI functionality as MCP tools.

**Target Users:** Musicians, sound designers, and developers who want to control MIDI hardware through natural language conversations with Claude AI.

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

**Development Mode:**
```bash
elixir run_mcp.exs        # Run the HTTP server (listens on port 3000)
PORT=8080 elixir run_mcp.exs  # Run on custom port
```

**Production Release:**
```bash
# Build a release for your current platform
MIX_ENV=prod mix release

# Run the release
_build/prod/rel/midi_ctrl/bin/midi_ctrl start

# Stop the release
_build/prod/rel/midi_ctrl/bin/midi_ctrl stop

# Run in daemon mode
_build/prod/rel/midi_ctrl/bin/midi_ctrl daemon
```

## Architecture

### Core Structure

The project implements an HTTP-based MCP server with three main modules:

- **`MIDICtrl.Router`** (lib/midi_ctrl/router.ex): The main HTTP router using Plug. Handles MCP JSON-RPC requests at `/mcp` endpoint and implements the MCP protocol methods (initialize, tools/list, tools/call, resources/list, resources/read). This is the entry point for the MCP server.

- **`MIDIOps`** (lib/midi_ops.ex): Contains MIDI operation implementations. Provides functions for:
  - `list_ports/0`: Query available MIDI ports
  - `send_cc_batch/4`: Send multiple CC changes with optional delays
  - `set_oscillator/3`: Switch MicroFreak oscillator types by name

- **`run_mcp.exs`**: Startup script that loads dependencies, starts the Bandit HTTP server on port 3000 (configurable via PORT env var), and keeps the server running.

### Key Dependencies

- **midiex** (~> 0.6.3): Elixir wrapper for MIDI functionality using Rust NIFs, providing access to MIDI ports and devices
- **bandit** (~> 1.8): Fast HTTP server built on Thousand Island
- **plug** (~> 1.18): Composable web middleware for HTTP request handling
- **jason** (~> 1.4): High-performance JSON encoding/decoding

### MCP Protocol Implementation

The server implements the MCP protocol via HTTP/JSON-RPC:

1. **HTTP Transport**: Uses Bandit HTTP server with Plug router
2. **JSON-RPC 2.0**: Handles MCP methods as JSON-RPC 2.0 requests
3. **MCP Methods Supported**:
   - `initialize`: Returns server capabilities and protocol version (2024-11-05)
   - `notifications/initialized`: Acknowledges initialization
   - `tools/list`: Returns available MIDI tools (list_ports, microfreak_cc, microfreak_set_oscillator)
   - `tools/call`: Executes tool requests with argument validation
   - `resources/list`: Lists available documentation resources
   - `resources/read`: Returns documentation content (MicroFreak MIDI reference)
   - `notifications/cancelled`: Handles cancellation notifications

### Request Flow

```
HTTP POST /mcp
  ↓
Plug.Parsers (extract JSON body)
  ↓
MIDICtrl.Router.call/2
  ↓
handle_mcp_method/3 (pattern match on method name)
  ↓
MIDIOps functions (MIDI operations)
  ↓
Midiex (Rust NIF → MIDI device)
  ↓
JSON-RPC 2.0 response
```

### Claude Desktop Integration

The server integrates with Claude Desktop via `mcp-remote`:

**Configuration file location:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**Config:**
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

The `mcp-remote` npm package bridges stdio (Claude Desktop's native protocol) to HTTP (MIDICtrl server).

### Adding New MCP Tools

To add new MCP tools:

1. **Add tool definition** in `MIDICtrl.Router.handle_mcp_method("tools/list", ...)` (lib/midi_ctrl/router.ex:51-172)
   ```elixir
   %{
     name: "your_tool_name",
     description: "Clear description of what the tool does",
     inputSchema: %{
       type: "object",
       properties: %{
         your_param: %{type: "string", description: "Param description"}
       },
       required: ["your_param"]
     }
   }
   ```

2. **Implement tool execution** in `MIDICtrl.Router.handle_mcp_method("tools/call", ...)` (lib/midi_ctrl/router.ex:193+)
   ```elixir
   defp handle_mcp_method("tools/call", id, %{"name" => "your_tool_name", "arguments" => args}) do
     # Validate arguments
     # Call MIDIOps function
     # Return success/error response
   end
   ```

3. **Add operation logic** in `MIDIOps` (lib/midi_ops.ex) or create new operation modules
   ```elixir
   def your_operation(args) do
     # MIDI logic using Midiex
   end
   ```

4. **Add tests** in `test/midi_ctrl_test.exs`

5. **Document** in `docs/` if it's device-specific (like MicroFreak reference)

### MIDI Port Information

MIDI ports have the following attributes:
- `name`: Human-readable port name (e.g., "Arturia MicroFreak")
- `direction`: `:input` or `:output`
- `num`: Port number identifier (used for connection)

### Error Handling

The codebase uses pattern matching and validation:
- Input validation before MIDI operations (channels 0-15, CC values 0-127)
- Port discovery with pattern matching
- Descriptive error messages in JSON-RPC error responses
- Resource cleanup (close connections after operations)

## Building Releases for Distribution

### Understanding Mix Releases

Since Elixir 1.9, `mix release` bundles the Erlang Runtime System (ERTS) so users don't need Elixir or Erlang installed. However, releases are **platform-specific**:

- macOS release → Only works on macOS
- Linux release → Only works on Linux (same architecture)
- Windows release → Only works on Windows

**Why platform-specific?** The `midiex` dependency uses Rust NIFs (Native Implemented Functions), which compile to machine code for the target platform.

### Building a Release Locally

```bash
# Set production environment
export MIX_ENV=prod

# Build release for your current platform
mix release

# Output location: _build/prod/rel/midi_ctrl/

# Test the release
_build/prod/rel/midi_ctrl/bin/midi_ctrl start
```

### Configuring Releases in mix.exs

To customize release configuration, add to `mix.exs`:

```elixir
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
        applications: [runtime_tools: :permanent]
      ]
    ]
  ]
end
```

### Cross-Platform Builds with CI/CD

To build releases for multiple platforms, use GitHub Actions:

**Create `.github/workflows/release.yml`:**

```yaml
name: Build Releases

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: '26.0'
          elixir-version: '1.19.0'
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - run: mix deps.get
      - run: MIX_ENV=prod mix release
      - run: tar -czf midi_ctrl-macos.tar.gz -C _build/prod/rel/midi_ctrl .
      - uses: actions/upload-artifact@v4
        with:
          name: midi_ctrl-macos
          path: midi_ctrl-macos.tar.gz

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: '26.0'
          elixir-version: '1.19.0'
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - run: mix deps.get
      - run: MIX_ENV=prod mix release
      - run: tar -czf midi_ctrl-linux.tar.gz -C _build/prod/rel/midi_ctrl .
      - uses: actions/upload-artifact@v4
        with:
          name: midi_ctrl-linux
          path: midi_ctrl-linux.tar.gz

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: '26.0'
          elixir-version: '1.19.0'
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - run: mix deps.get
      - run: $env:MIX_ENV="prod"; mix release
      - run: Compress-Archive -Path _build/prod/rel/midi_ctrl/* -DestinationPath midi_ctrl-windows.zip
      - uses: actions/upload-artifact@v4
        with:
          name: midi_ctrl-windows
          path: midi_ctrl-windows.zip

  create-release:
    needs: [build-macos, build-linux, build-windows]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
      - uses: softprops/action-gh-release@v1
        with:
          files: |
            midi_ctrl-macos/midi_ctrl-macos.tar.gz
            midi_ctrl-linux/midi_ctrl-linux.tar.gz
            midi_ctrl-windows/midi_ctrl-windows.zip
```

**To trigger builds:**
```bash
# Create and push a tag
git tag v0.1.0
git push origin v0.1.0

# GitHub Actions will build releases for all platforms
# and create a GitHub Release with downloadable artifacts
```

## Project Structure

```
midi_ctrl/
├── lib/
│   ├── midi_ctrl/
│   │   └── router.ex          # HTTP router & MCP protocol handler
│   └── midi_ops.ex             # MIDI operations (ports, CC, oscillators)
├── test/
│   ├── midi_ctrl_test.exs      # Unit tests for validation
│   └── test_helper.exs         # ExUnit configuration
├── docs/
│   └── microfreak_midi_reference.md  # Complete MicroFreak MIDI docs
├── .github/
│   └── workflows/
│       └── release.yml         # CI/CD for multi-platform releases
├── run_mcp.exs                 # Server startup script
├── mix.exs                     # Project configuration & dependencies
├── mix.lock                    # Dependency lock file
├── README.md                   # User documentation
├── CLAUDE.md                   # This file (developer guide)
├── LICENSE                     # MIT License
├── .formatter.exs              # Code formatting rules
└── .gitignore                  # Git ignore rules
```

## Current MCP Tools

### 1. list_ports
- **Purpose:** Discover available MIDI devices
- **Implementation:** `MIDIOps.list_ports/0`
- **Returns:** Formatted string with device info

### 2. microfreak_cc
- **Purpose:** Send Control Change messages (batch operations supported)
- **Implementation:** `MIDIOps.send_cc_batch/4`
- **Validation:** Channel (0-15), CC number (0-127), CC value (0-127)
- **Features:** Pattern matching for port names, configurable delays

### 3. microfreak_set_oscillator
- **Purpose:** Switch between 22 oscillator types using names
- **Implementation:** `MIDIOps.set_oscillator/3`
- **Mapping:** Oscillator names → CC 9 values (0-127, evenly distributed)

## Contributing Guidelines

### Code Style
- Follow Elixir conventions (snake_case for functions, CamelCase for modules)
- Run `mix format` before committing
- Use descriptive variable names
- Add typespecs for public functions

### Testing
- Add tests for new functionality
- Validate input ranges (MIDI channels, CC values, etc.)
- Test error conditions and edge cases
- Run `mix test` before submitting PRs

### Documentation
- Update README.md for user-facing changes
- Update CLAUDE.md for architecture changes
- Add MIDI references in `docs/` for new device support
- Include examples in docstrings

### Pull Requests
- Describe what the PR does and why
- Reference any related issues
- Include test coverage
- Ensure CI passes

## Roadmap & Ideas

### Potential Features
- **More MIDI Operations:**
  - Program Change (switch patches)
  - SysEx support (device-specific messages)
  - Note On/Off (play melodies)
  - Pitch Bend

- **Additional Synthesizers:**
  - Moog Subsequent/Matriarch
  - Korg Minilogue/Prologue
  - Roland JD-Xi/JD-08
  - Novation Bass Station

- **Enhanced Functionality:**
  - MIDI learn mode (detect CC numbers from device)
  - Preset management (save/load parameter sets)
  - MIDI clock sync
  - Multi-device orchestration

- **Developer Experience:**
  - Hot reload in development
  - Better logging and debugging
  - Web UI for testing tools
  - OpenAPI/Swagger spec

## Resources

- **MCP Specification:** https://modelcontextprotocol.io
- **Midiex Documentation:** https://hexdocs.pm/midiex
- **Elixir Releases:** https://hexdocs.pm/mix/Mix.Tasks.Release.html
- **Bandit HTTP Server:** https://github.com/mtrudel/bandit
- **Plug Documentation:** https://hexdocs.pm/plug

## Getting Help

- **Issues:** Report bugs or request features on GitHub Issues
- **Discussions:** Ask questions in GitHub Discussions
- **MCP Discord:** Join the Model Context Protocol community
- **Elixir Forum:** https://elixirforum.com for Elixir-specific questions

---

**This project is designed to be contributor-friendly.** Whether you're adding support for a new synthesizer, improving error handling, or enhancing documentation, contributions are welcome!

If you're using Claude Code to contribute, this file should give you all the context you need to understand the architecture and make changes confidently.
