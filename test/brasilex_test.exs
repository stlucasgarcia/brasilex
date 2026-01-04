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

      assert_raise Brasilex.ValidationError, ~r/Invalid length/, fn ->
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

  # ===========================================================================
  # IE (State Registration) - Delegate Tests
  # ===========================================================================

  describe "validate_ie/1" do
    test "returns :ok for valid IE" do
      assert :ok = Brasilex.validate_ie("110.042.490.114")
    end

    test "returns error for invalid IE" do
      assert {:error, :invalid_length} = Brasilex.validate_ie("12345")
      assert {:error, :invalid_format} = Brasilex.validate_ie("ABC123456")
      assert {:error, :invalid_checksum} = Brasilex.validate_ie("110042490115")
    end
  end

  describe "validate_ie!/1" do
    test "returns :ok for valid IE" do
      assert :ok = Brasilex.validate_ie!("110.042.490.114")
    end

    test "raises ValidationError for invalid IE" do
      assert_raise Brasilex.ValidationError, ~r/Invalid length/, fn ->
        Brasilex.validate_ie!("12345")
      end
    end
  end

  describe "parse_ie/1" do
    test "returns list of IEs for valid input" do
      assert {:ok, [ie]} = Brasilex.parse_ie("110.042.490.114")
      assert ie.state == :sp
      assert ie.raw == "110042490114"
    end

    test "returns multiple IEs when multiple states match" do
      assert {:ok, ies} = Brasilex.parse_ie("820000000")
      assert length(ies) > 1
      states = Enum.map(ies, & &1.state)
      assert :am in states
    end

    test "returns error for invalid IE" do
      assert {:error, :invalid_length} = Brasilex.parse_ie("12345")
    end
  end

  describe "parse_ie!/1" do
    test "returns list of IEs for valid input" do
      ies = Brasilex.parse_ie!("110.042.490.114")
      assert [ie] = ies
      assert ie.state == :sp
    end

    test "raises ValidationError for invalid IE" do
      assert_raise Brasilex.ValidationError, fn ->
        Brasilex.parse_ie!("12345")
      end
    end
  end

  describe "ValidationError" do
    test "formats unknown_type message" do
      error = Brasilex.ValidationError.exception(reason: :unknown_type)
      assert error.message == "Unknown type: could not identify document type"
      assert error.reason == :unknown_type
    end

    test "formats invalid_field_checksum message" do
      error = Brasilex.ValidationError.exception(reason: {:invalid_field_checksum, 2})
      assert error.message == "Invalid check digit in field 2"
      assert error.reason == {:invalid_field_checksum, 2}
    end

    test "formats unknown reason with fallback" do
      error = Brasilex.ValidationError.exception(reason: :some_unknown_error)
      assert error.message == "Validation failed: :some_unknown_error"
      assert error.reason == :some_unknown_error
    end
  end
end
