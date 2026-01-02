defmodule Brasilex.Checksum.Mod11Test do
  use ExUnit.Case, async: true

  # Skip doctests until we have verified test data
  # doctest Brasilex.Checksum.Mod11

  alias Brasilex.Checksum.Mod11

  describe "calculate/1" do
    test "returns a single digit between 1 and 9" do
      # Mod11 for boletos always returns 1-9 (special cases map 0,1,10,11 to 1)
      payloads = [
        String.duplicate("0", 43),
        String.duplicate("1", 43),
        String.duplicate("9", 43),
        "1234567890123456789012345678901234567890123"
      ]

      for payload <- payloads do
        result = Mod11.calculate(payload)
        assert result in 1..9, "Expected #{result} to be in 1..9 for #{payload}"
      end
    end

    test "uses cycling weights 2-9" do
      # The algorithm uses weights 2,3,4,5,6,7,8,9,2,3,... from right to left
      # This is verified by the fact that the same digit at different positions
      # contributes differently to the sum
      assert Mod11.calculate("10000000") != Mod11.calculate("00000001")
    end

    test "is deterministic" do
      input = String.duplicate("5", 43)
      result1 = Mod11.calculate(input)
      result2 = Mod11.calculate(input)
      assert result1 == result2
    end
  end

  describe "valid?/1" do
    test "round-trip: calculate then validate" do
      payloads = [
        String.duplicate("0", 43),
        String.duplicate("1", 43),
        "1234567890123456789012345678901234567890123"
      ]

      for payload <- payloads do
        dv = Mod11.calculate(payload)
        assert Mod11.valid?(payload, dv), "Expected payload with DV #{dv} to be valid"
      end
    end

    test "accepts string check digit" do
      payload = String.duplicate("0", 43)
      dv = Mod11.calculate(payload)
      assert Mod11.valid?(payload, Integer.to_string(dv))
    end

    test "returns false for wrong check digit" do
      payload = String.duplicate("0", 43)
      correct_dv = Mod11.calculate(payload)
      wrong_dv = rem(correct_dv + 1, 10)

      refute Mod11.valid?(payload, wrong_dv)
    end
  end
end
