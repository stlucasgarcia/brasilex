defmodule Brasilex.IE.ParserTest do
  use ExUnit.Case, async: true

  alias Brasilex.IE.Parser

  describe "parse/1" do
    test "parses SP IE correctly (single state match)" do
      assert {:ok, [ie]} = Parser.parse("110.042.490.114")
      assert ie.state == :sp
      assert ie.raw == "110042490114"
      assert ie.formatted == "110.042.490.114"
    end

    test "parses MG IE correctly (single state match)" do
      assert {:ok, [ie]} = Parser.parse("0623079040081")
      assert ie.state == :mg
      assert ie.raw == "0623079040081"
    end

    test "returns multiple IEs for shared algorithms" do
      # Use prefix "82" which doesn't conflict with any specific prefix validator
      assert {:ok, ies} = Parser.parse("820000000")

      states = Enum.map(ies, & &1.state)
      assert :am in states
      assert :sc in states
      assert :se in states

      # All should have the same raw value
      assert Enum.all?(ies, &(&1.raw == "820000000"))
    end

    test "each IE has correct state-specific formatting" do
      # Use prefix "82" which doesn't conflict with any specific prefix validator
      assert {:ok, ies} = Parser.parse("820000000")

      am_ie = Enum.find(ies, &(&1.state == :am))
      sc_ie = Enum.find(ies, &(&1.state == :sc))
      se_ie = Enum.find(ies, &(&1.state == :se))

      # AM format: NN.NNN.NNN-N
      assert am_ie.formatted == "82.000.000-0"
      # SC format: NNN.NNN.NNN
      assert sc_ie.formatted == "820.000.000"
      # SE format: NNNNNNNN-N
      assert se_ie.formatted == "82000000-0"
    end

    test "returns error for invalid IE" do
      assert {:error, :invalid_checksum} = Parser.parse("110042490115")
    end

    test "returns error for invalid length" do
      assert {:error, :invalid_length} = Parser.parse("12345")
    end
  end
end
