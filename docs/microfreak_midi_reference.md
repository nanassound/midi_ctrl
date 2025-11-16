# Arturia MicroFreak MIDI CC Reference

This document provides a reference for controlling the Arturia MicroFreak synthesizer via MIDI CC (Control Change) messages using the `microfreak_cc` tool.

## Quick Reference Table

| Parameter | CC# | Range | Section | Description |
|-----------|-----|-------|---------|-------------|
| **Glide** | 5 | 0-127 | General | Portamento/glide time |
| **Oscillator Type** | 9 | 0-127 | Oscillator | Select oscillator type |
| **Wave** | 10 | 0-127 | Oscillator | Waveform selection |
| **Timbre** | 12 | 0-127 | Oscillator | Timbral character |
| **Shape** | 13 | 0-127 | Oscillator | Waveform shape |
| **Filter Cutoff** | 23 | 0-127 | Filter | Low-pass filter cutoff frequency |
| **Filter Amount** | 26 | 0-127 | Envelope | Envelope modulation to filter |
| **Cycling Env Hold** | 28 | 0-127 | Cycling Envelope | Hold time |
| **Envelope Sustain** | 29 | 0-127 | Envelope | Sustain level |
| **Filter Resonance** | 83 | 0-127 | Filter | Filter resonance/Q |
| **ARP/SEQ Rate (free)** | 91 | 0-127 | Arpeggiator/Sequencer | Free-running tempo |
| **ARP/SEQ Rate (sync)** | 92 | 0-127 | Arpeggiator/Sequencer | Tempo-synced rate |
| **LFO Rate (free)** | 93 | 0-127 | LFO | Free-running LFO speed |
| **LFO Rate (sync)** | 94 | 0-127 | LFO | Tempo-synced LFO rate |
| **Cycling Env Rise** | 102 | 0-127 | Cycling Envelope | Attack/rise time |
| **Cycling Env Fall** | 103 | 0-127 | Cycling Envelope | Decay/fall time |
| **Cycling Env Amount** | 24 | 0-127 | Cycling Envelope | Modulation amount |
| **Envelope Attack** | 105 | 0-127 | Envelope | Attack time |
| **Envelope Decay** | 106 | 0-127 | Envelope | Decay time |
| **Keyboard Hold** | 64 | 0-127 | Keyboard | Hold button toggle (sustain pedal) |
| **Keyboard Spice** | 2 | 0-127 | Keyboard | Spice/dice randomization |

## Usage Examples

### Basic Filter Sweep
```elixir
# Slowly open the filter cutoff
microfreak_cc(
  port_pattern: "MicroFreak",
  cc_changes: [
    %{cc: 23, value: 100}  # Filter cutoff
  ]
)
```

### Sound Design - Bright Pad
```elixir
# Create a bright pad sound
microfreak_cc(
  port_pattern: "MicroFreak",
  cc_changes: [
    %{cc: 23, value: 90},   # Filter cutoff (bright)
    %{cc: 83, value: 30},   # Resonance (moderate)
    %{cc: 105, value: 60},  # Envelope attack (slow)
    %{cc: 106, value: 80},  # Envelope decay (long)
    %{cc: 29, value: 100}   # Sustain (high)
  ]
)
```

### Bass Sound
```elixir
# Create a punchy bass sound
microfreak_cc(
  port_pattern: "MicroFreak",
  cc_changes: [
    %{cc: 23, value: 40},   # Filter cutoff (dark)
    %{cc: 83, value: 70},   # Resonance (high)
    %{cc: 105, value: 0},   # Envelope attack (fast)
    %{cc: 106, value: 40},  # Envelope decay (short)
    %{cc: 29, value: 0}     # Sustain (none)
  ]
)
```

### Modulation Effects
```elixir
# Add movement with cycling envelope
microfreak_cc(
  port_pattern: "MicroFreak",
  cc_changes: [
    %{cc: 102, value: 50},  # Cycling env rise
    %{cc: 103, value: 50},  # Cycling env fall
    %{cc: 28, value: 20},   # Cycling env hold
    %{cc: 24, value: 80}    # Cycling env amount (high modulation)
  ]
)
```

### Sequencer Control
```elixir
# Set sequencer to a moderate tempo
microfreak_cc(
  port_pattern: "MicroFreak",
  cc_changes: [
    %{cc: 92, value: 64}    # ARP/SEQ rate (sync)
  ]
)
```

## Tips

1. **CC Values**: All CC values range from 0-127
   - 0 = minimum
   - 64 = center/50%
   - 127 = maximum

2. **MIDI Channel**: Default is channel 0 (MIDI channel 1). Make sure your MicroFreak is set to receive on the same channel.

3. **Batch Operations**: Send multiple CC changes at once for efficient sound design. The changes are sent sequentially with minimal delay.

4. **Finding Your Device**: Use the `list_ports` tool first to see available MIDI ports and confirm the exact name of your MicroFreak.

5. **Delay Between Messages**: If you experience issues with rapid parameter changes, add a small `delay_ms` (e.g., 10-20ms) between messages.

## Complete MIDI Implementation CSV

```csv
manufacturer,device,section,parameter_name,parameter_description,cc_msb,cc_lsb,cc_min_value,cc_max_value,nrpn_msb,nrpn_lsb,nrpn_min_value,nrpn_max_value,orientation,notes,usage
Arturia,MicroFreak,General,Glide,,5,,0,127,,,,,0-based,,
Arturia,MicroFreak,Oscillator,Type,,9,,0,127,,,,,0-based,,
Arturia,MicroFreak,Oscillator,Wave,,10,,0,127,,,,,0-based,,
Arturia,MicroFreak,Oscillator,Timbre,,12,,0,127,,,,,0-based,,
Arturia,MicroFreak,Oscillator,Shape,,13,,0,127,,,,,0-based,,
Arturia,MicroFreak,Filter,Cutoff,,23,,0,127,,,,,0-based,,
Arturia,MicroFreak,Filter,Resonance,,83,,0,127,,,,,0-based,,
Arturia,MicroFreak,Cycling envelope,Cycling env rise,,102,,0,127,,,,,0-based,,
Arturia,MicroFreak,Cycling envelope,Cycling env fall,,103,,0,127,,,,,0-based,,
Arturia,MicroFreak,Cycling envelope,Cycling env hold,,28,,0,127,,,,,0-based,,
Arturia,MicroFreak,Cycling envelope,Cycling env amount,,24,,0,127,,,,,0-based,,
Arturia,MicroFreak,Arpeggiator/sequencer,ARP/SEQ rate (free),,91,,0,127,,,,,0-based,,
Arturia,MicroFreak,Arpeggiator/sequencer,ARP/SEQ rate (sync),,92,,0,127,,,,,0-based,,
Arturia,MicroFreak,LFO,LFO rate (free),,93,,0,127,,,,,0-based,,
Arturia,MicroFreak,LFO,LFO rate (sync),,94,,0,127,,,,,0-based,,
Arturia,MicroFreak,Envelope,Envelope attack,,105,,0,127,,,,,0-based,,
Arturia,MicroFreak,Envelope,Envelope decay,,106,,0,127,,,,,0-based,,
Arturia,MicroFreak,Envelope,Envelope sustain,,29,,0,127,,,,,0-based,,
Arturia,MicroFreak,Envelope,Filter amount,,26,,0,127,,,,,0-based,,
Arturia,MicroFreak,Keyboard,Keyboard hold button (toggle),,64,,0,127,,,,,0-based,,
Arturia,MicroFreak,Keyboard,Keyboard spice,,2,,0,127,,,,,0-based,,
```

## Oscillator type in MicroFreak (CC 9) from first to last

Wave (CC 10), Timbre (CC 12), Shape (CC 13) will control different parameter for each oscillator.

**Note:** Use the `microfreak_set_oscillator` tool to switch oscillator types by name. The tool automatically maps oscillator names to their correct CC 9 values.

### Oscillator Type CC 9 Value Mapping

| Position | Oscillator Type | CC 9 Value | Tool Name |
|----------|----------------|------------|-----------|
| 0 | Basic Waves | 0 | BasicWaves |
| 1 | SuperWave | 6 | SuperWave |
| 2 | Wavetable | 12 | Wavetable |
| 3 | Harmo | 18 | Harmo |
| 4 | Karplus Strong | 24 | KarplusStr |
| 5 | V. Analog | 30 | V.Analog |
| 6 | Waveshaper | 36 | Waveshaper |
| 7 | Two Op. FM | 42 | TwoOpFM |
| 8 | Formant | 48 | Formant |
| 9 | Chords | 55 | Chords |
| 10 | Speech | 61 | Speech |
| 11 | Modal | 67 | Modal |
| 12 | Noise | 73 | Noise |
| 13 | Bass | 79 | Bass |
| 14 | SawX | 85 | SawX |
| 15 | Noise Engineering Harm | 91 | HarmNE |
| 16 | Wave User | 97 | WaveUser |
| 17 | Sample | 103 | Sample |
| 18 | Scan Grains | 109 | ScanGrains |
| 19 | Cloud Grains | 115 | CloudGrains |
| 20 | Hit Grains | 121 | HitGrains |
| 21 | Vocoder | 127 | Vocoder |

*Values are evenly distributed across the 0-127 range with 22 oscillator types (step size ≈6.05)*

### Oscillator Parameters

```csv
Oscillator type,wave,timbre,shape
BasicWaves,Morph,Sym,Sub
SuperWave,Wave (saw;square;triangle;sinus),Detune,Volume
Wavetable,Table,Position,Chorus
Harmo,Content,Sculpting,Chorus
KarplusStr,Bow,Position,Decay
V. Analog (virtual analog),Detune,Shape,Wave
Waveshaper,Wave,Amount,Asym
Two Op. FM,Ratio,Amount,Feedback
Formant,Interval,Formant,Shape
Chords,Type (oct;5;sus4;m;m7;m9;m11;69;M9;M7;M),Inv/Trsp,Waveform
Speech,Type,Timbre,Word
Modal,Inharm,Timbre,Decay
Noise,Type,Rate,Balance
Bass,Saturate,Fold,Noise
SawX,SawMod,Shape,Noise
Noise Engineering Harm,Spread,Rectify,Noise
WaveUser,Table,Position,Bitdepth
Sample,Start,Length,Loop
Scan Grains,Scan,Density,Chaos
Cloud Grains,Start,Density,Chaos
Hit Grains,Start,Density,Shape
Vocoder,Start,Density,Shape
```

## Future Enhancements

Planned features for future versions:
- Note sequencing (send Note On/Off messages)
- Preset save/recall functionality
- Named parameter interface (use "cutoff" instead of CC 23)
- MIDI learn capability
- Real-time parameter automation
