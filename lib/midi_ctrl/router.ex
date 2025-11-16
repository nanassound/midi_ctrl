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
        capabilities: %{tools: %{}},
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
            description: "List all available MIDI ports on the system with their names, directions (input/output), and port numbers",
            inputSchema: %{
              type: "object",
              properties: %{}
            }
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

  # Catch-all for unknown routes
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
