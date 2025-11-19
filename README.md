# MIDICtrl

**Control Arturia MicroFreak synthesizer with AI**

MIDICtrl is an HTTP-based [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server that bridges MCP-compatible LLMs with Arturia MicroFreak synthesizer. Adjust parameters, switch oscillator types, or explore sounds—all through natural language conversation. Works with any LLM client that supports the MCP protocol.

```
You: "Make the filter brighter and increase resonance"
AI: *adjusts Filter Cutoff (CC 23) and Resonance (CC 83) on your MicroFreak*
```

## Demo

<iframe width="560" height="315" src="https://www.youtube.com/embed/pDzP7qzEF6I?si=ELqUYcA2CCqG9pd3" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## What is This?

### MIDI (Musical Instrument Digital Interface)
MIDI is a protocol that lets electronic musical instruments, computers, and audio equipment communicate. Instead of transmitting audio, MIDI sends messages like "play note C4" or "set filter cutoff to 80."

**Key MIDI Concepts:**
- **MIDI Port**: A connection point to send/receive MIDI messages (like USB or hardware connections)
- **MIDI Channel**: 16 separate channels (0-15) for routing messages to different instruments
- **CC (Control Change)**: Messages that adjust parameters like volume, filter, or effects (0-127 range)
- **Port Direction**:
  - *Input ports* receive MIDI (e.g., from keyboards to your computer)
  - *Output ports* send MIDI (e.g., from your computer to synthesizers)

### MCP (Model Context Protocol)
MCP is Anthropic's open protocol that lets AI assistants safely interact with external tools and data sources. MIDICtrl exposes MIDI functionality as MCP tools that any compatible LLM can call during conversations.

**How It Works:**
```
You chat with an MCP-compatible AI client (e.g., Claude Desktop)
         ↓
The AI uses MIDICtrl tools (list ports, send CC messages, etc.)
         ↓
MIDICtrl translates requests to MIDI
         ↓
Your Arturia MicroFreak responds
```

## Features

- **MIDI Port Discovery**: List all connected MIDI devices
- **MicroFreak Control Changes**: Adjust any CC parameter on your MicroFreak
- **Batch Operations**: Send multiple parameter changes in one command
- **Named Oscillator Types**: Switch between 22 oscillator types using friendly names
- **LLM-Friendly**: Natural language interface—no MIDI knowledge required for basic use
- **Documentation as Resources**: Full MicroFreak MIDI reference accessible to the AI

## Quick Start

### Prerequisites

**For macOS users (pre-built release):**
- macOS computer
- Arturia MicroFreak connected via USB
- MCP-compatible AI client (e.g., Claude Desktop)

**For Linux/Windows users or developers:**
- Elixir 1.19+ and Erlang/OTP
- Arturia MicroFreak connected via USB
- MCP-compatible AI client (e.g., Claude Desktop)

### Installation

#### Option 1: Pre-built Release (macOS only)

**Note:** Pre-built releases are coming soon. Once available:

```bash
# Download the macOS release
wget https://github.com/nanassound/midi_ctrl/releases/download/v0.1.0/midi_ctrl-macos-arm.tar.gz

# Extract
tar -xzf midi_ctrl-macos-arm.tar.gz
cd midi_ctrl

# Start the server (no Elixir/Erlang required!)
./bin/midi_ctrl start

# Server runs on http://localhost:3000
```

#### Option 2: From Source (Linux/Windows/Mac)

```bash
# Clone the repository
git clone https://github.com/nanassound/midi_ctrl.git
cd midi_ctrl

# Install dependencies
mix deps.get

# Run the server
elixir run_mcp.exs

# Server starts on http://localhost:3000
```

**Building Your Own Release (Optional):**

If you want to create a standalone release for your platform:

```bash
# Build release
MIX_ENV=prod mix release

# The release will be in _build/prod/rel/midi_ctrl/
# Start it with:
_build/prod/rel/midi_ctrl/bin/midi_ctrl start
```

**Note:** Releases are platform-specific. A release built on macOS won't work on Linux/Windows.

### Configure Your MCP Client

Add MIDICtrl to your MCP client configuration. Here's an example for Claude Desktop:

**macOS/Linux:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

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

**Restart your MCP client** after saving the configuration.

### Verify Connection

1. Start the MIDICtrl server (see Installation above)
2. Open your MCP client (e.g., Claude Desktop)
3. Look for the tools name in your LLM UI
4. Try: "What MIDI ports do you see?"

The AI should list your connected MIDI devices using the `list_ports` tool.

## Usage Examples

### Basic: List Your MIDI Devices

```
You: "What MIDI devices are connected?"

AI: *uses list_ports tool*

I can see you have these MIDI devices:
- Arturia MicroFreak (output, port 2)
- USB MIDI Interface (input, port 0)
```

### Control Change Messages

```
You: "Set the filter cutoff to 100 and resonance to 80 on my MicroFreak"

AI: *uses microfreak_cc tool with CC 23 (cutoff) and CC 83 (resonance)*

I've adjusted your MicroFreak:
- Filter Cutoff: 100
- Filter Resonance: 80
```

### Switch Oscillator Types

```
You: "Switch my MicroFreak to the Wavetable oscillator"

AI: *uses microfreak_set_oscillator tool*

Done! Your MicroFreak is now using the Wavetable oscillator.
```

### Creative Sound Design

```
You: "Create a warm pad sound on my MicroFreak"

AI: I'll set up a warm pad for you:
- Oscillator: SuperWave (for richness)
- Filter Cutoff: 60 (darker tone)
- Resonance: 30 (subtle emphasis)
- Attack: 40 (slow fade-in)
- Release: 70 (long tail)

*sends multiple CC changes*

Try playing now—you should have a lush, warm pad sound!
```

## Available Tools

### 1. `list_ports`

Discover all connected MIDI devices.

**Arguments:** None

**Returns:** List of MIDI ports with:
- `name`: Device name (e.g., "Arturia MicroFreak")
- `direction`: `input` or `output`
- `num`: Port number identifier

**Example:**
```
name: Arturia MicroFreak
direction: output
num: 2
```

### 2. `microfreak_cc`

Send MIDI Control Change messages to adjust Arturia MicroFreak parameters.

**Arguments:**
- `port_pattern` (string, required): Pattern to match MIDI port name (e.g., "MicroFreak")
- `cc_changes` (array, required): List of CC changes `[{cc: number, value: number}]`
- `channel` (integer, optional): MIDI channel 0-15 (default: 0)
- `delay_ms` (integer, optional): Delay between messages in milliseconds (default: 0)

**Common MicroFreak CC Numbers:**
- CC 23: Filter Cutoff (0-127, brightness)
- CC 83: Filter Resonance (0-127, emphasis)
- CC 12: Timbre (0-127, tonal character)
- CC 13: Shape (0-127, waveform shape)
- CC 105: Envelope Attack (0-127, fade-in time)
- CC 106: Envelope Decay (0-127, fade-out time)
- CC 29: Envelope Sustain (0-127, held level)
- CC 9: Oscillator Type (0-127, see oscillator types)

**Full CC reference:** See [docs/microfreak_midi_reference.md](docs/microfreak_midi_reference.md)

**Example:**
```json
{
  "port_pattern": "MicroFreak",
  "cc_changes": [
    {"cc": 23, "value": 100},
    {"cc": 83, "value": 60}
  ],
  "channel": 0
}
```

### 3. `microfreak_set_oscillator`

Switch between 22 oscillator types on the Arturia MicroFreak using friendly names.

**Arguments:**
- `port_pattern` (string, required): Pattern to match MIDI port name
- `oscillator_type` (string, required): Oscillator name (see below)
- `channel` (integer, optional): MIDI channel 0-15 (default: 0)

**Available Oscillator Types (22 total):**

| Name | Description |
|------|-------------|
| BasicWaves | Classic analog waveforms (saw, square, triangle) |
| SuperWave | Thick, detuned sawtooth waves |
| Wavetable | Morphing wavetable synthesis |
| Harmo | Harmonic additive synthesis |
| KarplusStr | Karplus-Strong string synthesis |
| V.Analog | Virtual analog modeling |
| Waveshaper | Waveshaping synthesis |
| TwoOpFM | Two-operator FM synthesis |
| Formant | Vocal formant synthesis |
| Chords | Chord generator |
| Speech | Speech synthesis |
| Modal | Modal resonator synthesis |
| Noise | Noise generator |
| Bass | Bass-optimized synthesis |
| SawX | Enhanced sawtooth |
| HarmNE | Harmonic noise engine |
| WaveUser | User wavetable |
| Sample | Sample playback |
| ScanGrains | Scanning granular synthesis |
| CloudGrains | Cloud granular synthesis |
| HitGrains | Percussive granular synthesis |
| Vocoder | Vocoder synthesis |

**Example:**
```json
{
  "port_pattern": "MicroFreak",
  "oscillator_type": "Wavetable",
  "channel": 0
}
```

## Example Prompts

Here are some creative ways to interact with your MicroFreak through an AI assistant:

**Exploration:**
- "What can you control on my MicroFreak?"
- "Show me what MIDI devices I have connected"
- "What oscillator types are available?"

**Sound Design:**
- "Create a bright, aggressive lead sound"
- "Make a deep, rumbling bass patch"
- "Give me a spacey ambient pad"
- "Randomize 5 parameters and surprise me"

**Learning:**
- "Explain what filter resonance does, then demonstrate it by sweeping from 0 to 127"
- "Show me the difference between the Wavetable and V.Analog oscillators"
- "Teach me about MIDI CC by adjusting different parameters"

**Precise Control:**
- "Set filter cutoff to 80, resonance to 40, and attack to 50"
- "Switch to the Modal oscillator and set timbre to 100"
- "Send CC 12 with value 64 to my synth"

## Advanced Topics

### For Developers & Contributors

See [CLAUDE.md](CLAUDE.md) for:
- Architecture and code structure
- Adding new MCP tools
- Development workflow
- Testing and formatting
- Building releases for distribution
- CI/CD setup

### MicroFreak MIDI Reference

See [docs/microfreak_midi_reference.md](docs/microfreak_midi_reference.md) for:
- Complete CC parameter list (30+ parameters)
- Oscillator-specific parameters
- Sound design examples
- MIDI implementation chart

### Adding Support for Other Synthesizers

Currently, MIDICtrl only supports the Arturia MicroFreak. To add support for other synthesizers:

1. Look up the MIDI implementation in your synth's manual (CC numbers and ranges)
2. Create new MCP tools in `lib/midi_ctrl/router.ex`
3. Add operation logic in `lib/midi_ops.ex`
4. Document CC mappings in `docs/your_synth_midi_reference.md`

Example tool names: `moog_cc`, `roland_cc`, `korg_patch_select`

Contributions adding support for other synthesizers are welcome!

## Troubleshooting

**"No MIDI ports found"**
- Ensure your MIDI device is powered on and connected
- Check your system's MIDI settings/drivers
- On macOS: Check Audio MIDI Setup application
- On Linux: Verify ALSA/JACK configuration
- Try unplugging and reconnecting the device

**"Port pattern didn't match any ports"**
- Run `list_ports` first to see exact device names
- Use partial matches (e.g., "Micro" instead of "Arturia MicroFreak")
- Check for typos in the port pattern

**"My MCP client doesn't see the MCP tools"**
- Verify the MIDICtrl server is running (check http://localhost:3000)
- Confirm your MCP client config is saved correctly
- Restart your MCP client after config changes
- Check for `npx` availability: `which npx` in terminal

**"Server won't start"**
- Check if port 3000 is already in use: `lsof -i :3000`
- Try a different port: `PORT=8080 elixir run_mcp.exs`
- Update config to match: `"http://localhost:8080/mcp"`

## Contributing

Contributions are welcome! Please see [CLAUDE.md](CLAUDE.md) for development setup and guidelines.

**Areas for contribution:**
- Support for additional synthesizers (Moog, Korg, Roland, Novation, etc.)
- More MIDI functionality for MicroFreak (program change, sysex, etc.)
- Better error handling and user feedback
- Pre-built releases for Linux and Windows
- Documentation improvements

## License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Nanas Sound

## Acknowledgments

- Built with [Elixir](https://elixir-lang.org/) and [Bandit](https://github.com/mtrudel/bandit)
- MIDI functionality via [Midiex](https://github.com/haubie/midiex)
- Implements [Model Context Protocol (MCP)](https://modelcontextprotocol.io) by Anthropic
- Inspired by the creative possibilities of AI-assisted music production

## Links

- **Documentation:** [CLAUDE.md](CLAUDE.md) (developers), [docs/](docs/) (MIDI references)
- **MCP Specification:** https://modelcontextprotocol.io
- **Claude Desktop:** https://claude.ai/download
- **Issues & Feedback:** [GitHub Issues](https://github.com/nanassound/midi_ctrl/issues)

---

**Made with AI assistance using Claude Code** 🎹🤖
