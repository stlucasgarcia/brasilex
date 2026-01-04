defmodule Brasilex.IE.FormatTest do
  @moduledoc """
  Tests for state-specific IE formatting via parse/1.
  Each state has its own format pattern applied when parsing.
  """
  use ExUnit.Case, async: true

  alias Brasilex.IE

  describe "SP formatting" do
    test "formats 12-digit regular IE" do
      assert {:ok, [ie]} = IE.parse("110042490114")
      assert ie.formatted == "110.042.490.114"
    end

    test "formats rural producer IE (P prefix)" do
      assert {:ok, [ie]} = IE.parse("P011004243002")
      assert ie.formatted == "P-01100424.3/002"
    end
  end

  describe "MG formatting" do
    test "formats 13-digit IE" do
      assert {:ok, [ie]} = IE.parse("0623079040081")
      assert ie.formatted == "062.307.904/0081"
    end
  end

  describe "RJ formatting" do
    test "formats 8-digit IE" do
      assert {:ok, [ie]} = IE.parse("99999993")
      assert ie.formatted == "99.999.99-3"
    end
  end

  describe "RS formatting" do
    test "formats 10-digit IE" do
      assert {:ok, [ie]} = IE.parse("2243658792")
      assert ie.formatted == "224/3658792"
    end
  end

  describe "PR formatting" do
    test "formats 10-digit IE" do
      assert {:ok, [ie]} = IE.parse("1234567850")
      assert ie.formatted == "123.45678-50"
    end
  end

  describe "AC formatting" do
    test "formats 13-digit IE" do
      assert {:ok, [ie]} = IE.parse("0100000000082")
      assert ie.formatted == "01.000.000/000-82"
    end
  end

  describe "DF formatting" do
    test "formats 13-digit IE" do
      assert {:ok, [ie]} = IE.parse("0730000100109")
      assert ie.formatted == "07.300001.001-09"
    end
  end

  describe "MT formatting" do
    test "formats 11-digit IE" do
      assert {:ok, [ie]} = IE.parse("00130000019")
      assert ie.formatted == "0013000001-9"
    end
  end

  describe "MS formatting" do
    test "formats 9-digit IE" do
      assert {:ok, [ie]} = IE.parse("280000006")
      assert ie.formatted == "28.000.000-6"
    end
  end

  describe "GO formatting" do
    test "formats 9-digit IE" do
      assert {:ok, ies} = IE.parse("109876547")
      go_ie = Enum.find(ies, &(&1.state == :go))
      assert go_ie.formatted == "10.987.654-7"
    end
  end

  describe "TO formatting" do
    test "formats 11-digit IE" do
      assert {:ok, [ie]} = IE.parse("29010227836")
      assert ie.formatted == "29.01.022783-6"
    end
  end

  describe "RO formatting" do
    test "formats 14-digit IE (new format)" do
      assert {:ok, ies} = IE.parse("00000000625213")
      ro_ie = Enum.find(ies, &(&1.state == :ro))
      assert ro_ie.formatted == "0000000062521-3"
    end

    test "formats 9-digit IE (legacy format)" do
      assert {:ok, [ie]} = IE.parse("101625213")
      assert ie.formatted == "101.62521-3"
    end
  end

  describe "RR formatting" do
    test "formats 9-digit IE" do
      assert {:ok, [ie]} = IE.parse("240061536")
      assert ie.formatted == "24006153-6"
    end
  end

  describe "RN formatting" do
    test "formats 9-digit IE" do
      assert {:ok, [ie]} = IE.parse("200400401")
      assert ie.formatted == "20.040.040-1"
    end

    test "formats 10-digit IE" do
      assert {:ok, [ie]} = IE.parse("2000400400")
      assert ie.formatted == "20.0.040.040-0"
    end
  end

  describe "PE formatting" do
    test "formats 14-digit CACEPE IE" do
      # PE CACEPE is unique to PE (14 digits)
      assert {:ok, ies} = IE.parse("18100100000049")
      pe_ie = Enum.find(ies, &(&1.state == :pe))
      assert pe_ie.formatted == "18.1.001.0000004-9"
    end
  end

  describe "BA formatting" do
    test "formats 8-digit IE" do
      assert {:ok, ies} = IE.parse("12345663")
      ba_ie = Enum.find(ies, &(&1.state == :ba))
      assert ba_ie.formatted == "123456-63"
    end

    test "formats 9-digit IE" do
      assert {:ok, [ie]} = IE.parse("100000306")
      assert ie.formatted == "1000003-06"
    end
  end

  describe "MA formatting" do
    test "formats 9-digit IE" do
      assert {:ok, [ie]} = IE.parse("120000385")
      assert ie.formatted == "12000038-5"
    end
  end

  describe "PA formatting" do
    test "formats 9-digit IE" do
      assert {:ok, [ie]} = IE.parse("159999995")
      assert ie.formatted == "15999999-5"
    end
  end

  describe "AL formatting (no special format)" do
    test "returns raw digits" do
      assert {:ok, ies} = IE.parse("240000048")
      al_ie = Enum.find(ies, &(&1.state == :al))
      assert al_ie.formatted == "240000048"
    end
  end

  describe "AP formatting (no special format)" do
    test "returns raw digits" do
      assert {:ok, [ie]} = IE.parse("030123459")
      assert ie.formatted == "030123459"
    end
  end

  describe "AM formatting" do
    test "formats 9-digit IE" do
      assert {:ok, ies} = IE.parse("820000000")
      am_ie = Enum.find(ies, &(&1.state == :am))
      assert am_ie.formatted == "82.000.000-0"
    end
  end

  describe "CE formatting" do
    test "formats 9-digit IE" do
      assert {:ok, ies} = IE.parse("060000015")
      ce_ie = Enum.find(ies, &(&1.state == :ce))
      assert ce_ie.formatted == "06000001-5"
    end
  end

  describe "ES formatting (no special format)" do
    test "returns raw digits" do
      assert {:ok, ies} = IE.parse("080000002")
      es_ie = Enum.find(ies, &(&1.state == :es))
      assert es_ie.formatted == "080000002"
    end
  end

  describe "PB formatting" do
    test "formats 9-digit IE" do
      assert {:ok, ies} = IE.parse("060000015")
      pb_ie = Enum.find(ies, &(&1.state == :pb))
      assert pb_ie.formatted == "06000001-5"
    end
  end

  describe "PI formatting (no special format)" do
    test "returns raw digits" do
      assert {:ok, ies} = IE.parse("012345679")
      pi_ie = Enum.find(ies, &(&1.state == :pi))
      assert pi_ie.formatted == "012345679"
    end
  end

  describe "SC formatting" do
    test "formats 9-digit IE" do
      assert {:ok, ies} = IE.parse("820000000")
      sc_ie = Enum.find(ies, &(&1.state == :sc))
      assert sc_ie.formatted == "820.000.000"
    end
  end

  describe "SE formatting" do
    test "formats 9-digit IE" do
      assert {:ok, ies} = IE.parse("820000000")
      se_ie = Enum.find(ies, &(&1.state == :se))
      assert se_ie.formatted == "82000000-0"
    end
  end
end
