defmodule MIDICtrlTest do
  use ExUnit.Case

  test "MIDIOps module is loaded" do
    assert Code.ensure_loaded?(MIDIOps)
  end

  test "MIDICtrl.Router module is loaded" do
    assert Code.ensure_loaded?(MIDICtrl.Router)
  end

  describe "MIDIOps.send_cc_batch/4" do
    test "validates MIDI channel range" do
      result = MIDIOps.send_cc_batch("test", [%{cc: 1, value: 64}], 16)
      assert {:error, "Invalid MIDI channel: 16. Must be 0-15."} = result
    end

    test "validates empty CC changes list" do
      result = MIDIOps.send_cc_batch("test", [], 0)
      assert {:error, "CC changes list cannot be empty"} = result
    end

    test "validates CC number range" do
      result = MIDIOps.send_cc_batch("test", [%{cc: 128, value: 64}], 0)
      assert {:error, "Invalid CC number: 128. Must be 0-127."} = result
    end

    test "validates CC value range" do
      result = MIDIOps.send_cc_batch("test", [%{cc: 23, value: 128}], 0)
      assert {:error, "Invalid CC value: 128. Must be 0-127."} = result
    end
  end
end
