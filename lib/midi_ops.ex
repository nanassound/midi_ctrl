defmodule MIDIOps do
  # MicroFreak oscillator types mapped to CC 9 values (evenly distributed 0-127)
  # 22 oscillator types: positions 0-21, step size ≈ 6.05
  @oscillator_types %{
    "BasicWaves" => 0,
    "SuperWave" => 6,
    "Wavetable" => 12,
    "Harmo" => 18,
    "KarplusStr" => 24,
    "V.Analog" => 30,
    "Waveshaper" => 36,
    "TwoOpFM" => 42,
    "Formant" => 48,
    "Chords" => 55,
    "Speech" => 61,
    "Modal" => 67,
    "Noise" => 73,
    "Bass" => 79,
    "SawX" => 85,
    "HarmNE" => 91,
    "WaveUser" => 97,
    "Sample" => 103,
    "ScanGrains" => 109,
    "CloudGrains" => 115,
    "HitGrains" => 121,
    "Vocoder" => 127
  }

  def list_ports do
    available_ports = Midiex.ports()

    Enum.reduce(available_ports, "", fn item, acc ->
      acc <> "name: #{item.name}\ndirection: #{item.direction}\nnum:#{item.num}\n===\n"
    end)
  end

  @doc """
  Set the oscillator type on the MicroFreak synthesizer.

  ## Parameters
    - port_pattern: String pattern to match against MIDI port names
    - oscillator_name: Name of the oscillator type (e.g., "Wavetable", "Bass", "Modal")
    - channel: MIDI channel (0-15), defaults to 0

  ## Returns
    - {:ok, message} on success
    - {:error, reason} on failure

  ## Available Oscillator Types
    BasicWaves, SuperWave, Wavetable, Harmo, KarplusStr, V.Analog, Waveshaper,
    TwoOpFM, Formant, Chords, Speech, Modal, Noise, Bass, SawX, HarmNE,
    WaveUser, Sample, ScanGrains, CloudGrains, HitGrains, Vocoder
  """
  def set_oscillator(port_pattern, oscillator_name, channel \\ 0) do
    case get_oscillator_cc(oscillator_name) do
      {:ok, cc_value} ->
        # Send CC 9 with the mapped value
        send_cc_batch(port_pattern, [%{cc: 9, value: cc_value}], channel)

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Get the CC value for a given oscillator type name.

  ## Parameters
    - oscillator_name: Name of the oscillator type (case-insensitive)

  ## Returns
    - {:ok, cc_value} if oscillator type is found
    - {:error, reason} if oscillator type is unknown
  """
  def get_oscillator_cc(oscillator_name) do
    # Normalize the name (case-insensitive, remove spaces/dots)
    normalized =
      oscillator_name
      |> String.replace(".", "")
      |> String.replace(" ", "")
      |> String.downcase()

    # Try to find a matching oscillator type (case-insensitive)
    result =
      Enum.find(@oscillator_types, fn {key, _value} ->
        String.downcase(key) == normalized
      end)

    case result do
      {_name, cc_value} ->
        {:ok, cc_value}

      nil ->
        available = Map.keys(@oscillator_types) |> Enum.join(", ")
        {:error, "Unknown oscillator type: '#{oscillator_name}'. Available types: #{available}"}
    end
  end

  @doc """
  Send a batch of MIDI CC (Control Change) messages to a MIDI output port.

  ## Parameters
    - port_pattern: String pattern to match against MIDI port names
    - cc_changes: List of maps with :cc and :value keys, e.g., [%{cc: 23, value: 100}]
    - channel: MIDI channel (0-15), defaults to 0
    - delay_ms: Optional delay between messages in milliseconds, defaults to 0

  ## Returns
    - {:ok, message} on success
    - {:error, reason} on failure
  """
  def send_cc_batch(port_pattern, cc_changes, channel \\ 0, delay_ms \\ 0) do
    # Validate inputs
    with :ok <- validate_channel(channel),
         :ok <- validate_cc_changes(cc_changes),
         {:ok, port} <- find_output_port(port_pattern),
         {:ok, conn} <- open_port(port),
         :ok <- send_cc_messages(conn, cc_changes, channel, delay_ms) do
      Midiex.close(conn)

      {:ok,
       "Successfully sent #{length(cc_changes)} CC message(s) to #{port.name} on channel #{channel}"}
    else
      {:error, _reason} = error -> error
    end
  end

  # Validate MIDI channel (0-15)
  defp validate_channel(channel) when channel >= 0 and channel <= 15, do: :ok
  defp validate_channel(channel), do: {:error, "Invalid MIDI channel: #{channel}. Must be 0-15."}

  # Validate CC changes list
  defp validate_cc_changes([]), do: {:error, "CC changes list cannot be empty"}

  defp validate_cc_changes(cc_changes) when is_list(cc_changes) do
    Enum.reduce_while(cc_changes, :ok, fn change, _acc ->
      case validate_cc_change(change) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_cc_changes(_), do: {:error, "CC changes must be a list"}

  # Validate individual CC change
  defp validate_cc_change(%{cc: cc, value: value}) when is_integer(cc) and is_integer(value) do
    cond do
      cc < 0 or cc > 127 -> {:error, "Invalid CC number: #{cc}. Must be 0-127."}
      value < 0 or value > 127 -> {:error, "Invalid CC value: #{value}. Must be 0-127."}
      true -> :ok
    end
  end

  defp validate_cc_change(_), do: {:error, "Each CC change must have :cc and :value keys"}

  # Find output port matching pattern
  defp find_output_port(pattern) do
    case Midiex.ports(pattern, :output) do
      [] -> {:error, "No output port found matching pattern: '#{pattern}'"}
      [port | _] -> {:ok, port}
    end
  end

  # Open MIDI port connection
  defp open_port(port) do
    try do
      conn = Midiex.open(port)
      {:ok, conn}
    rescue
      e -> {:error, "Failed to open port: #{Exception.message(e)}"}
    end
  end

  # Send all CC messages
  defp send_cc_messages(conn, cc_changes, channel, delay_ms) do
    Enum.reduce_while(cc_changes, :ok, fn %{cc: cc, value: value}, _acc ->
      try do
        cc_msg = Midiex.Message.control_change(cc, value, channel: channel)
        Midiex.send_msg(conn, cc_msg)

        # Add delay between messages if specified
        if delay_ms > 0, do: Process.sleep(delay_ms)

        {:cont, :ok}
      rescue
        e -> {:halt, {:error, "Failed to send CC #{cc}: #{Exception.message(e)}"}}
      end
    end)
  end
end
