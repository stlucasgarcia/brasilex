defmodule Brasilex.Checksum.Mod9Test do
  use ExUnit.Case, async: true

  doctest Brasilex.Checksum.Mod9

  alias Brasilex.Checksum.Mod9

  describe "calculate/1" do
    test "calculates check digit for Roraima IE examples" do
      # Examples from SEFAZ RR documentation
      assert Mod9.calculate("24006628") == 1
      assert Mod9.calculate("24001755") == 6
      assert Mod9.calculate("24003429") == 0
      assert Mod9.calculate("24001360") == 3
      assert Mod9.calculate("24008266") == 8
      assert Mod9.calculate("24006153") == 6
      assert Mod9.calculate("24007356") == 2
      assert Mod9.calculate("24005467") == 4
      assert Mod9.calculate("24004145") == 5
      assert Mod9.calculate("24001340") == 7
    end

    test "handles all zeros" do
      assert Mod9.calculate("00000000") == 0
    end

    test "handles single digit" do
      assert Mod9.calculate("5") == 5
    end
  end

  describe "valid?/1" do
    test "returns true for valid Roraima IEs" do
      # Examples from SEFAZ RR documentation
      assert Mod9.valid?("240066281")
      assert Mod9.valid?("240017556")
      assert Mod9.valid?("240034290")
      assert Mod9.valid?("240013603")
      assert Mod9.valid?("240082668")
      assert Mod9.valid?("240061536")
      assert Mod9.valid?("240073562")
      assert Mod9.valid?("240054674")
      assert Mod9.valid?("240041455")
      assert Mod9.valid?("240013407")
    end

    test "returns false for invalid check digit" do
      refute Mod9.valid?("240066280")
      refute Mod9.valid?("240066289")
    end

    test "returns false for empty string" do
      refute Mod9.valid?("")
    end

    test "returns false for single digit" do
      refute Mod9.valid?("5")
    end
  end
end
