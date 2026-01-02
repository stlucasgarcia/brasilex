defmodule BrasilexTest do
  use ExUnit.Case, async: true

  # We'll generate valid boletos dynamically rather than hardcoding
  # since the checksums must be calculated correctly

  describe "validate_boleto/1 - error cases" do
    test "returns error for too short input" do
      assert {:error, :invalid_length} = Brasilex.validate_boleto("123456789")
    end

    test "returns error for too long input" do
      assert {:error, :invalid_length} = Brasilex.validate_boleto(String.duplicate("0", 50))
    end

    test "returns error for empty string" do
      assert {:error, :invalid_format} = Brasilex.validate_boleto("")
    end

    test "returns error for 47 digits with invalid field 1 checksum" do
      # 47 zeros - field 1 payload "001900000" should have DV 9, not 0
      # First 4 chars (0019) + 5 zeros + wrong DV (0) = invalid field 1
      invalid = "0019000000" <> String.duplicate("0", 37)
      result = Brasilex.validate_boleto(invalid)
      assert {:error, {:invalid_field_checksum, 1}} = result
    end

    test "returns error for unknown convenio type (48 digits not starting with 8)" do
      # 48 digits starting with 9 (not 8) is unknown type
      invalid = "9" <> String.duplicate("0", 47)
      assert {:error, :unknown_type} = Brasilex.validate_boleto(invalid)
    end
  end

  describe "parse_boleto/1 - error cases" do
    test "returns error for invalid input" do
      assert {:error, :invalid_format} = Brasilex.parse_boleto("")
      assert {:error, :invalid_length} = Brasilex.parse_boleto("12345")
    end
  end

  describe "validate_boleto!/1" do
    test "raises ValidationError for invalid boleto" do
      assert_raise Brasilex.ValidationError, ~r/Invalid format/, fn ->
        Brasilex.validate_boleto!("")
      end

      assert_raise Brasilex.ValidationError, ~r/Invalid linha digitável length/, fn ->
        Brasilex.validate_boleto!("12345")
      end
    end
  end

  describe "parse_boleto!/1" do
    test "raises ValidationError for invalid input" do
      assert_raise Brasilex.ValidationError, fn ->
        Brasilex.parse_boleto!("12345")
      end
    end
  end

  describe "input sanitization" do
    test "strips dots from input" do
      # Even if the boleto is invalid, dots should be stripped
      input = "00190.00000.00000.00000.00000.00000.00000.00000.000"
      result = Brasilex.validate_boleto(input)
      # Should fail on checksum, not format
      assert {:error, reason} = result
      assert reason != :invalid_format
    end

    test "strips spaces from input" do
      input = "0019 0000 0000 0000 0000 0000 0000 0000 0000 0000 000"
      result = Brasilex.validate_boleto(input)
      assert {:error, reason} = result
      assert reason != :invalid_format
    end

    test "strips hyphens from input" do
      input = "0019-0000-0000-0000-0000-0000-0000-0000-0000-0000-000"
      result = Brasilex.validate_boleto(input)
      assert {:error, reason} = result
      assert reason != :invalid_format
    end
  end

  describe "Boleto struct helpers" do
    test "banking?/1 returns correct values" do
      banking = %Brasilex.Boleto{type: :banking, raw: "", barcode: "", free_field: ""}
      convenio = %Brasilex.Boleto{type: :convenio, raw: "", barcode: "", free_field: ""}

      assert Brasilex.Boleto.banking?(banking)
      refute Brasilex.Boleto.banking?(convenio)
    end

    test "convenio?/1 returns correct values" do
      banking = %Brasilex.Boleto{type: :banking, raw: "", barcode: "", free_field: ""}
      convenio = %Brasilex.Boleto{type: :convenio, raw: "", barcode: "", free_field: ""}

      refute Brasilex.Boleto.convenio?(banking)
      assert Brasilex.Boleto.convenio?(convenio)
    end
  end
end
