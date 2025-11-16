defmodule MIDIOps do
  def list_ports do
    available_ports = Midiex.ports()
    Enum.reduce(available_ports, "", fn item, acc ->
      acc <> "name: #{item.name}\ndirection: #{item.direction}\nnum:#{item.num}\n===\n"
    end)
  end
end
