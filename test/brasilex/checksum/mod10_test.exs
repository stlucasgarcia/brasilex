defmodule Brasilex.Checksum.Mod10Test do
  use ExUnit.Case, async: true
  doctest Brasilex.Checksum.Mod10

  alias Brasilex.Checksum.Mod10

  describe "calculate/1" do
    test "calculates correct check digit for FEBRABAN examples" do
      # These are verified against FEBRABAN documentation
      assert Mod10.calculate("341911012") == 1
      assert Mod10.calculate("3456788005") == 8
    end

    test "handles all zeros" do
      assert Mod10.calculate("0000000000") == 0
    end

    test "calculates for boleto field examples" do
      # Bank code 237, currency 9, free field 33812
      # Verified: 237933812 -> DV should be 8
      assert Mod10.calculate("237933812") == 8
    end

    test "calculate is deterministic" do
      input = "123456789"
      result1 = Mod10.calculate(input)
      result2 = Mod10.calculate(input)
      assert result1 == result2
      assert result1 in 0..9
    end
  end

  describe "valid?/1" do
    test "returns true for valid sequences with correct DV appended" do
      # 341911012 has DV 1
      assert Mod10.valid?("3419110121")
      # 3456788005 has DV 8
      assert Mod10.valid?("34567880058")
      # 237933812 has DV 8
      assert Mod10.valid?("2379338128")
    end

    test "returns false for invalid sequences" do
      # Wrong DV (should be 1, using 9)
      refute Mod10.valid?("3419110129")
      # Wrong DV (should be 8, using 0)
      refute Mod10.valid?("34567880050")
      # Wrong DV (should be 8, using 1)
      refute Mod10.valid?("2379338121")
    end

    test "returns false for empty string" do
      refute Mod10.valid?("")
    end

    test "returns false for single digit" do
      refute Mod10.valid?("5")
    end

    test "round-trip: calculate then validate" do
      # Any input should become valid when we append its calculated DV
      payloads = ["123456789", "000000000", "111111111", "987654321"]

      for payload <- payloads do
        dv = Mod10.calculate(payload)
        full = payload <> Integer.to_string(dv)
        assert Mod10.valid?(full), "Expected #{full} to be valid"
      end
    end
  end
end
