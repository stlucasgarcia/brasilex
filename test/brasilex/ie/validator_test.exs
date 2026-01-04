defmodule Brasilex.IE.ValidatorTest do
  use ExUnit.Case, async: true

  alias Brasilex.IE.Validator

  describe "sanitize/1" do
    test "removes dots, hyphens, slashes, and spaces" do
      assert {:ok, "110042490114"} = Validator.sanitize("110.042.490.114")
      assert {:ok, "271234563"} = Validator.sanitize("27123456-3")
      assert {:ok, "0623079040081"} = Validator.sanitize("062.307.904/0081")
      assert {:ok, "2243658792"} = Validator.sanitize("224/3658792")
      assert {:ok, "110042490114"} = Validator.sanitize("110 042 490 114")
    end

    test "preserves P prefix for SP rural producer" do
      assert {:ok, "P011004243002"} = Validator.sanitize("P-01100424.3/002")
    end

    test "returns error for non-digit characters" do
      assert {:error, :invalid_format} = Validator.sanitize("ABC123456")
      assert {:error, :invalid_format} = Validator.sanitize("12345678X")
    end

    test "returns error for invalid length" do
      # 8 digits is now valid for BA, so use 7 for too short
      assert {:error, :invalid_length} = Validator.sanitize("1234567")
      assert {:error, :invalid_length} = Validator.sanitize("123456789012345")
    end
  end

  describe "validate/1 - São Paulo (SP)" do
    test "validates regular SP IE (12 digits)" do
      assert :ok = Validator.validate("110.042.490.114")
      assert :ok = Validator.validate("110042490114")
    end

    test "validates SP rural producer format (P + 12 digits)" do
      assert :ok = Validator.validate("P-01100424.3/002")
      assert :ok = Validator.validate("P011004243002")
    end
  end

  describe "validate/1 - Minas Gerais (MG)" do
    test "validates MG IE (13 digits)" do
      assert :ok = Validator.validate("062.307.904/0081")
      assert :ok = Validator.validate("0623079040081")
    end
  end

  describe "validate/1 - Santa Catarina (SC)" do
    test "validates SC IE (9 digits)" do
      # Using a prefix outside GO range (01-09, 12-19, 30-99) to avoid GO detection
      # SC: 123456785 -> (1*9)+(2*8)+(3*7)+(4*6)+(5*5)+(6*4)+(7*3)+(8*2) = 9+16+21+24+25+24+21+16 = 156
      # 156 mod 11 = 2, 11 - 2 = 9 (but check digit is 5, let's recalculate)
      # Actually let me use the documented example with correct calculation
      # 251.040.852 has prefix 25 which is valid for GO, so let's use a different test
      # For 12345678X: (1*9)+(2*8)+(3*7)+(4*6)+(5*5)+(6*4)+(7*3)+(8*2) = 156, 156 mod 11 = 2, 11-2 = 9
      assert :ok = Validator.validate("123456789")
    end

    test "SC state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.SC.validate("12345")
    end
  end

  describe "validate/1 - Sergipe (SE)" do
    test "validates SE IE (9 digits)" do
      assert :ok = Validator.validate("27123456-3")
      assert :ok = Validator.validate("271234563")
    end

    test "SE state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.SE.validate("12345")
    end
  end

  describe "validate/1 - Mato Grosso do Sul (MS)" do
    test "validates MS IE (9 digits, prefix 28)" do
      # We need to generate a valid MS IE for testing
      # MS prefix is 28, weights 9,8,7,6,5,4,3,2
      # 28000000 -> (2*9)+(8*8)+(0*7)+(0*6)+(0*5)+(0*4)+(0*3)+(0*2) = 18+64 = 82
      # 82 mod 11 = 5, 11 - 5 = 6
      assert :ok = Validator.validate("28.000.000-6")
      assert :ok = Validator.validate("280000006")
    end

    test "returns error for wrong prefix" do
      assert {:error, :invalid_checksum} = Validator.validate("27.000.000-6")
    end

    test "MS state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.MS.validate("12345")
      assert {:error, :invalid_prefix} = Brasilex.IE.States.MS.validate("270000006")
    end
  end

  describe "validate/1 - Goiás (GO)" do
    test "validates GO IE (9 digits, prefixes 10/11/20-29)" do
      assert :ok = Validator.validate("10.987.654-7")
      assert :ok = Validator.validate("109876547")
    end

    test "GO state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.GO.validate("12345")
    end

    test "GO state module returns error for wrong prefix" do
      assert {:error, :invalid_prefix} = Brasilex.IE.States.GO.validate("300000000")
    end
  end

  describe "validate/1 - Rio Grande do Sul (RS)" do
    test "validates RS IE (10 digits)" do
      assert :ok = Validator.validate("224/3658792")
      assert :ok = Validator.validate("2243658792")
    end

    test "RS state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.RS.validate("12345")
    end
  end

  describe "validate/1 - Roraima (RR)" do
    test "validates RR IE (9 digits, prefix 24, Mod9)" do
      # From SEFAZ RR documentation
      assert :ok = Validator.validate("24006628-1")
      assert :ok = Validator.validate("24001755-6")
      assert :ok = Validator.validate("24006153-6")
      assert :ok = Validator.validate("240061536")
    end

    test "returns error for wrong prefix" do
      assert {:error, :invalid_checksum} = Validator.validate("250061536")
    end

    test "RR state module returns error for wrong length" do
      # Direct call to RR module for coverage
      assert {:error, :invalid_length} = Brasilex.IE.States.RR.validate("12345")
      assert {:error, :invalid_prefix} = Brasilex.IE.States.RR.validate("250061536")
    end
  end

  describe "validate/1 - Rio Grande do Norte (RN)" do
    test "validates RN IE (9 or 10 digits, prefix 20)" do
      assert :ok = Validator.validate("20.040.040-1")
      assert :ok = Validator.validate("200400401")
      assert :ok = Validator.validate("20.0.040.040-0")
      assert :ok = Validator.validate("2000400400")
    end
  end

  describe "validate/1 - Tocantins (TO)" do
    test "validates TO IE (11 digits with type codes)" do
      assert :ok = Validator.validate("29.01.022783-6")
      assert :ok = Validator.validate("29010227836")
    end

    test "returns error for invalid type code" do
      # Type code 05 is invalid (only 01, 02, 03, 99 are valid)
      # With auto-detection, invalid type codes result in no state matching
      assert {:error, :invalid_checksum} = Validator.validate("29050227836")
    end
  end

  describe "validate/1 - Rondônia (RO)" do
    test "validates RO IE (14 digits, new format)" do
      assert :ok = Validator.validate("0000000062521-3")
      assert :ok = Validator.validate("00000000625213")
    end

    test "validates RO IE (9 digits, legacy format)" do
      assert :ok = Validator.validate("101.62521-3")
      assert :ok = Validator.validate("101625213")
    end
  end

  describe "validate/1 - Mato Grosso (MT)" do
    test "validates MT IE (11 digits)" do
      assert :ok = Validator.validate("0013000001-9")
      assert :ok = Validator.validate("00130000019")
    end

    test "MT state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.MT.validate("12345")
    end
  end

  describe "validate/1 - Acre (AC)" do
    test "validates AC IE (13 digits, prefix 01)" do
      # AC uses 2 check digits with specific weight sequences
      # Prefix is always "01"
      # 0100000000082: D1=8, D2=2 calculated from weights
      assert :ok = Validator.validate("0100000000082")
    end
  end

  describe "validate/1 - Alagoas (AL)" do
    test "validates AL IE (9 digits, prefix 24, valid type)" do
      # AL uses prefix 24 with type code at position 3
      # Valid types: 0, 3, 5, 7, 8
      assert :ok = Validator.validate("240000048")
    end

    test "returns error for invalid type code" do
      # Type 1 is invalid for AL
      assert {:error, :invalid_checksum} = Validator.validate("241000048")
    end

    test "AL state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.AL.validate("12345")
    end

    test "AL state module returns error for wrong prefix" do
      assert {:error, :invalid_prefix} = Brasilex.IE.States.AL.validate("250000048")
    end
  end

  describe "validate/1 - Amapá (AP)" do
    test "validates AP IE (9 digits, prefix 03)" do
      # AP uses prefix "03" with special p/d values based on ranges
      assert :ok = Validator.validate("030123459")
    end

    test "returns error for wrong prefix" do
      assert {:error, :invalid_checksum} = Validator.validate("040123459")
    end
  end

  describe "validate/1 - Amazonas (AM)" do
    test "validates AM IE (9 digits)" do
      # AM uses standard mod11 with special case when sum < 11
      # 120000008: payload=12000000, sum=25, 25 mod 11=3, 11-3=8
      assert :ok = Validator.validate("120000008")
    end

    test "AM state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.AM.validate("12345")
    end
  end

  describe "validate/1 - Bahia (BA)" do
    test "validates BA IE (8 digits, mod10)" do
      # First digit 0-5,8 uses mod10
      assert :ok = Validator.validate("123456-63")
      assert :ok = Validator.validate("12345663")
    end

    test "validates BA IE (8 digits, mod11)" do
      # First digit 6,7,9 uses mod11
      assert :ok = Validator.validate("612345-57")
      assert :ok = Validator.validate("61234557")
    end

    test "validates BA IE (9 digits)" do
      # 9 digit format uses second digit for modulo determination
      assert :ok = Validator.validate("1000003-06")
      assert :ok = Validator.validate("100000306")
    end
  end

  describe "validate/1 - Ceará (CE)" do
    test "validates CE IE (9 digits)" do
      # CE uses Mod11 weights 9-2
      # Example from documentation: 06000001-5
      assert :ok = Validator.validate("06000001-5")
      assert :ok = Validator.validate("060000015")
    end

    test "CE state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.CE.validate("12345")
    end
  end

  describe "validate/1 - Espírito Santo (ES)" do
    test "validates ES IE (9 digits)" do
      # ES uses Mod11 weights 9-2
      # 08000000X: (0*9)+(8*8)+(0*7)+(0*6)+(0*5)+(0*4)+(0*3)+(0*2) = 64
      # 64 mod 11 = 9, 11 - 9 = 2
      assert :ok = Validator.validate("080000002")
    end
  end

  describe "validate/1 - Paraná (PR)" do
    test "validates PR IE (10 digits)" do
      # PR uses 2 check digits with weights 3,2,7,6,5,4,3,2 and 4,3,2,7,6,5,4,3,2
      # Example from documentation: 123.45678-50
      assert :ok = Validator.validate("123.45678-50")
      assert :ok = Validator.validate("1234567850")
    end
  end

  describe "validate/1 - Piauí (PI)" do
    test "validates PI IE (9 digits)" do
      # PI uses Mod11 weights 9-2
      # Example from documentation: 01234567-9
      assert :ok = Validator.validate("01234567-9")
      assert :ok = Validator.validate("012345679")
    end
  end

  describe "validate/1 - Pernambuco (PE)" do
    test "validates PE IE eFisco format (9 digits)" do
      # PE eFisco: 7 base + 2 check digits
      # Example from documentation: 0321418-40
      assert :ok = Validator.validate("0321418-40")
      assert :ok = Validator.validate("032141840")
    end

    test "validates PE IE legacy CACEPE format (14 digits)" do
      # PE legacy: 13 base + 1 check digit
      # Example from documentation: 18.1.001.0000004-9
      assert :ok = Validator.validate("18.1.001.0000004-9")
      assert :ok = Validator.validate("18100100000049")
    end
  end

  describe "validate/1 - Maranhão (MA)" do
    test "validates MA IE (9 digits, prefix 12)" do
      # MA uses Mod11 weights 9-2, prefix "12"
      # Example from documentation: 12000038-5
      assert :ok = Validator.validate("12000038-5")
      assert :ok = Validator.validate("120000385")
    end

    test "MA prefix 12 is required" do
      # MA validator requires prefix "12"
      # When using a different prefix, it falls through to other validators
      # This test verifies that MA-specific validation works
      assert :ok = Validator.validate("120000385")
    end

    test "MA state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.MA.validate("12345")
    end

    test "MA state module returns error for wrong prefix" do
      assert {:error, :invalid_prefix} = Brasilex.IE.States.MA.validate("130000385")
    end
  end

  describe "validate/1 - Pará (PA)" do
    test "validates PA IE (9 digits, prefix 15)" do
      # PA uses Mod11 weights 9-2, prefixes 15, 75-79
      # Example from documentation: 15999999-5
      assert :ok = Validator.validate("15999999-5")
      assert :ok = Validator.validate("159999995")
    end

    test "validates PA IE (9 digits, prefix 75)" do
      # Example from documentation: 75000002-3
      assert :ok = Validator.validate("75000002-3")
      assert :ok = Validator.validate("750000023")
    end

    test "returns error for invalid prefix" do
      assert {:error, :invalid_checksum} = Validator.validate("160000023")
    end

    test "PA state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.PA.validate("12345")
    end

    test "PA state module returns error for wrong prefix" do
      assert {:error, :invalid_prefix} = Brasilex.IE.States.PA.validate("160000023")
    end
  end

  describe "validate/1 - Paraíba (PB)" do
    test "validates PB IE (9 digits)" do
      # PB uses Mod11 weights 9-2
      # Example from documentation: 06000001-5
      assert :ok = Validator.validate("06000001-5")
      assert :ok = Validator.validate("060000015")
    end

    test "PB state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.PB.validate("12345")
    end
  end

  describe "validate/1 - Rio de Janeiro (RJ)" do
    test "validates RJ IE (8 digits)" do
      # RJ uses Mod11 weights 2,7,6,5,4,3,2
      # Example from documentation: 99.999.99-3
      assert :ok = Validator.validate("99.999.99-3")
      assert :ok = Validator.validate("99999993")
    end

    test "RJ state module returns error for wrong length" do
      assert {:error, :invalid_length} = Brasilex.IE.States.RJ.validate("12345")
    end
  end

  describe "validate/1 - Distrito Federal (DF)" do
    test "validates DF IE (13 digits, prefix 07)" do
      # DF uses 2 check digits with weights 2-9 sequence
      # Example from documentation: 07.300001.001-09
      assert :ok = Validator.validate("07.300001.001-09")
      assert :ok = Validator.validate("0730000100109")
    end

    test "returns error for wrong prefix" do
      assert {:error, :invalid_checksum} = Validator.validate("0830000100109")
    end
  end

  describe "validate/1 - error cases" do
    test "returns error for too short input" do
      assert {:error, :invalid_length} = Validator.validate("1234567")
    end

    test "returns error for too long input" do
      assert {:error, :invalid_length} = Validator.validate("123456789012345")
    end

    test "returns error for non-digit characters" do
      assert {:error, :invalid_format} = Validator.validate("ABC123456")
    end

    test "returns error for invalid checksum" do
      # Valid format but wrong check digit
      assert {:error, :invalid_checksum} = Validator.validate("110042490115")
    end
  end

  describe "detect_state/1" do
    test "detects São Paulo" do
      assert {:ok, :sp} = Validator.detect_state("110042490114")
    end

    test "detects Minas Gerais" do
      assert {:ok, :mg} = Validator.detect_state("0623079040081")
    end

    test "detects states with shared algorithms" do
      # Multiple states use identical Mod11 weights 9-2 algorithm
      # Use prefix "82" which doesn't conflict with any specific prefix validator
      # 820000000 is valid for multiple states
      result = Validator.detect_state("820000000")

      assert result in [
               {:ok, :am},
               {:ok, :ce},
               {:ok, :es},
               {:ok, :pb},
               {:ok, :pi},
               {:ok, :sc},
               {:ok, :se}
             ]
    end

    test "detects Roraima" do
      assert {:ok, :rr} = Validator.detect_state("240061536")
    end

    test "detects Rio Grande do Sul" do
      assert {:ok, :rs} = Validator.detect_state("2243658792")
    end

    test "detects Acre" do
      assert {:ok, :ac} = Validator.detect_state("0100000000082")
    end

    test "detects Alagoas" do
      assert {:ok, :al} = Validator.detect_state("240000048")
    end

    test "detects Amapá" do
      assert {:ok, :ap} = Validator.detect_state("030123459")
    end

    test "detects Amazonas" do
      # Use a prefix that doesn't conflict with MA (12), AP (03), etc.
      # 820000001: payload=82000000, sum=(8*9)+(2*8)+(0*7)... = 72+16 = 88
      # 88 mod 11 = 0, digit = 0. So 820000000 is valid for AM.
      assert {:ok, :am} = Validator.detect_state("820000000")
    end

    test "detects Bahia (8 digits)" do
      assert {:ok, :ba} = Validator.detect_state("12345663")
    end

    test "detects Bahia (9 digits)" do
      assert {:ok, :ba} = Validator.detect_state("100000306")
    end

    test "detects Paraná" do
      assert {:ok, :pr} = Validator.detect_state("1234567850")
    end

    test "detects Pernambuco (legacy CACEPE)" do
      # Use the legacy 14-digit format which is unique to PE
      # Example from documentation: 18.1.001.0000004-9
      assert {:ok, :pe} = Validator.detect_state("18100100000049")
    end

    test "detects Maranhão" do
      assert {:ok, :ma} = Validator.detect_state("120000385")
    end

    test "detects Pará" do
      assert {:ok, :pa} = Validator.detect_state("159999995")
    end

    test "detects Rio de Janeiro" do
      # RJ uses unique weights 2,7,6,5,4,3,2 - different from BA
      assert {:ok, :rj} = Validator.detect_state("99999993")
    end

    test "detects Distrito Federal" do
      assert {:ok, :df} = Validator.detect_state("0730000100109")
    end
  end

  describe "detect_states/1" do
    test "returns multiple states for shared algorithms" do
      # Use prefix "82" which doesn't conflict with any specific prefix validator
      # 820000000 is valid for AM, CE, ES, PB, PI, SC, SE (all use Mod11 weights 9-2)
      assert {:ok, states} = Validator.detect_states("820000000")
      assert :am in states
      assert :ce in states
      assert :es in states
      assert :pb in states
      assert :pi in states
      assert :sc in states
      assert :se in states
    end

    test "returns single state for unique algorithms" do
      # SP has unique 12-digit format
      assert {:ok, [:sp]} = Validator.detect_states("110042490114")
    end

    test "returns multiple states for prefix 24 (RR and AL)" do
      # Prefix 24 is valid for both RR (Mod9) and AL (Mod11)
      # but only one will have correct checksum for a given IE
      assert {:ok, states} = Validator.detect_states("240061536")
      assert :rr in states
    end

    test "returns error for invalid IE" do
      assert {:error, :invalid_checksum} = Validator.detect_states("123456780")
    end

    test "returns error for invalid length" do
      assert {:error, :invalid_length} = Validator.detect_states("12345")
    end
  end
end
