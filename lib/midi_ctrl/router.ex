defmodule MIDICtrl.Router do
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # Health check endpoint
  get "/" do
    send_resp(conn, 200, "MIDI Ctrl MCP Server is running")
  end

  # MCP endpoint - handle JSON-RPC requests
  post "/mcp" do
    method = Map.get(conn.body_params, "method")
    id = Map.get(conn.body_params, "id")
    params = Map.get(conn.body_params, "params", %{})

    response = handle_mcp_method(method, id, params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end

  defp handle_mcp_method("initialize", id, _params) do
    %{
      jsonrpc: "2.0",
      id: id,
      result: %{
        protocolVersion: "2024-11-05",
        capabilities: %{
          tools: %{},
          resources: %{}
        },
        serverInfo: %{name: "MIDI Ctrl", version: "0.1.0"}
      }
    }
  end

  defp handle_mcp_method("notifications/initialized", nil, _params) do
    %{}
  end

  defp handle_mcp_method("tools/list", id, _params) do
    %{
      jsonrpc: "2.0",
      id: id,
      result: %{
        tools: [
          %{
            name: "list_ports",
            description:
              "List all available MIDI ports on the system with their names, directions (input/output), and port numbers",
            inputSchema: %{
              type: "object",
              properties: %{}
            }
          },
          %{
            name: "microfreak_cc",
            description:
              "Send MIDI CC (Control Change) messages to control synthesizer parameters. Supports batch operations to change multiple parameters at once. Useful for sound design, controlling filters, envelopes, oscillators, LFOs, and more.",
            inputSchema: %{
              type: "object",
              properties: %{
                port_pattern: %{
                  type: "string",
                  description:
                    "Pattern to match MIDI port name (e.g., 'MicroFreak', 'Arturia', or exact port name from list_ports)"
                },
                cc_changes: %{
                  type: "array",
                  description:
                    "Array of CC changes to send. Each change specifies a CC number and value.",
                  items: %{
                    type: "object",
                    properties: %{
                      cc: %{
                        type: "integer",
                        description:
                          "MIDI CC number (0-127). Common MicroFreak CCs: 23=Filter Cutoff, 83=Resonance, 12=Timbre, 13=Shape, 105=Env Attack, 106=Env Decay",
                        minimum: 0,
                        maximum: 127
                      },
                      value: %{
                        type: "integer",
                        description: "CC value (0-127)",
                        minimum: 0,
                        maximum: 127
                      }
                    },
                    required: ["cc", "value"]
                  }
                },
                channel: %{
                  type: "integer",
                  description:
                    "MIDI channel (0-15, where 0 = channel 1). Optional, defaults to 0",
                  minimum: 0,
                  maximum: 15
                },
                delay_ms: %{
                  type: "integer",
                  description:
                    "Delay between CC messages in milliseconds. Optional, defaults to 0",
                  minimum: 0
                }
              },
              required: ["port_pattern", "cc_changes"]
            }
          }
        ]
      }
    }
  end

  defp handle_mcp_method("resources/list", id, _params) do
    %{
      jsonrpc: "2.0",
      id: id,
      result: %{
        resources: [
          %{
            uri: "microfreak://midi-reference",
            name: "MicroFreak MIDI Reference",
            description:
              "Complete MIDI CC reference for Arturia MicroFreak synthesizer including parameter tables, examples, and oscillator types",
            mimeType: "text/markdown"
          }
        ]
      }
    }
  end

  defp handle_mcp_method("tools/call", id, %{"name" => "list_ports"} = _params) do
    ports_info = MIDIOps.list_ports()

    %{
      jsonrpc: "2.0",
      id: id,
      result: %{
        content: [
          %{
            type: "text",
            text: ports_info
          }
        ]
      }
    }
  end

  defp handle_mcp_method("tools/call", id, %{"name" => "microfreak_cc", "arguments" => args}) do
    # Extract arguments with defaults
    port_pattern = Map.get(args, "port_pattern")
    cc_changes_raw = Map.get(args, "cc_changes", [])
    channel = Map.get(args, "channel", 0)
    delay_ms = Map.get(args, "delay_ms", 0)

    # Convert cc_changes from JSON format (string keys) to Elixir format (atom keys)
    cc_changes =
      Enum.map(cc_changes_raw, fn change ->
        %{
          cc: Map.get(change, "cc"),
          value: Map.get(change, "value")
        }
      end)

    # Call the MIDI operation
    case MIDIOps.send_cc_batch(port_pattern, cc_changes, channel, delay_ms) do
      {:ok, message} ->
        %{
          jsonrpc: "2.0",
          id: id,
          result: %{
            content: [
              %{
                type: "text",
                text: message
              }
            ]
          }
        }

      {:error, reason} ->
        %{
          jsonrpc: "2.0",
          id: id,
          error: %{
            code: -32603,
            message: "MIDI operation failed: #{reason}"
          }
        }
    end
  end

  defp handle_mcp_method("resources/read", id, %{"uri" => uri} = _params) do
    case uri do
      "microfreak://midi-reference" ->
        content = read_microfreak_reference()

        %{
          jsonrpc: "2.0",
          id: id,
          result: %{
            contents: [
              %{
                uri: "microfreak://midi-reference",
                mimeType: "text/markdown",
                text: content
              }
            ]
          }
        }

      _ ->
        %{
          jsonrpc: "2.0",
          id: id,
          error: %{
            code: -32602,
            message: "Unknown resource URI: #{uri}"
          }
        }
    end
  end

  defp handle_mcp_method("notifications/cancelled", nil, _params) do
    %{}
  end

  defp handle_mcp_method(method, id, _params) do
    %{
      jsonrpc: "2.0",
      id: id,
      error: %{
        code: -32601,
        message: "Method not found: #{method}"
      }
    }
  end

  # Helper function to read MicroFreak reference documentation
  defp read_microfreak_reference do
    path = Path.join([__DIR__, "..", "..", "docs", "microfreak_midi_reference.md"])

    case File.read(path) do
      {:ok, content} ->
        content

      {:error, :enoent} ->
        raise "MicroFreak reference file not found at: #{path}"

      {:error, reason} ->
        raise "Failed to read MicroFreak reference: #{reason}"
    end
  end

  # Catch-all for unknown routes
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
