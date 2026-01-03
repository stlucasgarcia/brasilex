defmodule Brasilex.IntegrationTest do
  @moduledoc """
  Integration tests that generate valid boletos dynamically using
  the checksum algorithms, then validate and parse them.
  """
  use ExUnit.Case, async: true

  alias Brasilex.Checksum.{Mod10, Mod11}

  describe "banking boleto (47 digits) round-trip" do
    test "generates, validates, and parses a valid banking boleto" do
      # Build a valid linha digitável with correct checksums
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "001",
        currency: "9",
        free_field: "0000000000000000000000000",
        due_factor: "0000",
        amount: "0000000000"
      )

      # Validate
      assert :ok = Brasilex.validate_boleto(linha_digitavel)

      # Parse
      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.type == :banking
      assert boleto.bank_code == "001"
      assert boleto.currency_code == "9"
      assert boleto.amount == nil  # zero amount = nil
      assert boleto.due_date == nil  # zero due factor = nil
    end

    test "parses amount correctly" do
      # R$ 150.00
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "237",
        currency: "9",
        free_field: "0000000000000000000000000",
        due_factor: "0000",
        amount: "0000015000"
      )

      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert Decimal.equal?(boleto.amount, Decimal.new("150.00"))
    end

    test "parses due date from old cycle (factor results in recent date)" do
      # Factor 9999 = 2025-02-21 using old base (last date of old cycle)
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "341",
        currency: "9",
        free_field: "0000000000000000000000000",
        due_factor: "9999",
        amount: "0000000100"
      )

      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.due_date == ~D[2025-02-21]
    end

    test "parses due date from new cycle (factor 1000 = 2025-02-22)" do
      # Factor 1000 with new base (2022-05-29) = 2025-02-22
      # This triggers new cycle because old base would give 2000-07-03 (>5 years ago)
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "341",
        currency: "9",
        free_field: "0000000000000000000000000",
        due_factor: "1000",
        amount: "0000000100"
      )

      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.due_date == ~D[2025-02-22]
    end

    test "extracts free field correctly" do
      free_field = "1234567890123456789012345"
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "033",
        currency: "9",
        free_field: free_field,
        due_factor: "0000",
        amount: "0000000000"
      )

      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.free_field == free_field
    end
  end

  describe "convenio boleto (48 digits) round-trip" do
    test "generates, validates, and parses a valid convenio boleto" do
      # Build a valid convenio boleto
      linha_digitavel = build_valid_convenio_boleto(
        segment: "6",
        amount: "00000000000",
        company_id: "00000000",
        free_field: "000000000000000000000"
      )

      # Validate
      assert :ok = Brasilex.validate_boleto(linha_digitavel)

      # Parse
      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.type == :convenio
      assert boleto.segment == "6"
    end

    test "parses real convenio boleto with correct amount" do
      # Real boleto: should parse to R$ 43.93
      linha_digitavel = "846600000000439300481009011290918405925127380374"

      assert :ok = Brasilex.validate_boleto(linha_digitavel)

      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.type == :convenio
      assert boleto.segment == "4"
      assert Decimal.equal?(boleto.amount, Decimal.new("43.93"))
      assert boleto.barcode == "84660000000439300481000112909184092512738037"
    end

    test "parses convenio boleto with formatted input" do
      # Real boleto with spaces: should parse to R$ 1471.48
      linha_digitavel = "836800000140 714800481000 087518989519 002527336537"

      assert :ok = Brasilex.validate_boleto(linha_digitavel)

      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.type == :convenio
      assert boleto.segment == "3"
      assert Decimal.equal?(boleto.amount, Decimal.new("1471.48"))
      assert boleto.company_id == "00481000"
      assert boleto.barcode == "83680000014714800481000875189895100252733653"
    end

    test "parses convenio boleto with Mod11 value type" do
      # Real boleto with value_type 8 (Mod11): should parse to R$ 87.74
      linha_digitavel = "85800000000 3 87740385253 5 53071625349 053617103333 0"

      assert :ok = Brasilex.validate_boleto(linha_digitavel)

      {:ok, boleto} = Brasilex.parse_boleto(linha_digitavel)
      assert boleto.type == :convenio
      assert boleto.segment == "5"
      assert Decimal.equal?(boleto.amount, Decimal.new("87.74"))
      assert boleto.barcode == "85800000000877403852535307162534953617103333"
    end
  end

  describe "formatted input" do
    test "accepts boleto with dots and spaces" do
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "001",
        currency: "9",
        free_field: "0000000000000000000000000",
        due_factor: "0000",
        amount: "0000000000"
      )

      # Add formatting
      formatted = format_banking_linha_digitavel(linha_digitavel)

      assert :ok = Brasilex.validate_boleto(formatted)
      {:ok, boleto} = Brasilex.parse_boleto(formatted)
      assert boleto.type == :banking
    end
  end

  describe "banking barcode (44 digits) round-trip" do
    test "validates and parses a banking barcode" do
      # First build a valid linha digitável with factor 9999 (old cycle)
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "237",
        currency: "9",
        free_field: "1234567890123456789012345",
        due_factor: "9999",
        amount: "0000015000"
      )

      # Parse to get the barcode
      {:ok, boleto_from_linha} = Brasilex.parse_boleto(linha_digitavel)
      barcode = boleto_from_linha.barcode

      # Validate the barcode directly
      assert :ok = Brasilex.validate_boleto(barcode)

      # Parse the barcode
      {:ok, boleto} = Brasilex.parse_boleto(barcode)
      assert boleto.type == :banking
      assert boleto.bank_code == "237"
      assert boleto.currency_code == "9"
      assert Decimal.equal?(boleto.amount, Decimal.new("150.00"))
      assert boleto.due_date == ~D[2025-02-21]
      assert boleto.free_field == "1234567890123456789012345"
    end

    test "barcode and linha digitável produce same parsed values" do
      linha_digitavel = build_valid_banking_boleto(
        bank_code: "001",
        currency: "9",
        free_field: "9876543210987654321098765",
        due_factor: "8434",
        amount: "0000019900"
      )

      {:ok, boleto_linha} = Brasilex.parse_boleto(linha_digitavel)
      {:ok, boleto_barcode} = Brasilex.parse_boleto(boleto_linha.barcode)

      assert boleto_linha.type == boleto_barcode.type
      assert boleto_linha.bank_code == boleto_barcode.bank_code
      assert boleto_linha.currency_code == boleto_barcode.currency_code
      assert boleto_linha.amount == boleto_barcode.amount
      assert boleto_linha.due_date == boleto_barcode.due_date
      assert boleto_linha.free_field == boleto_barcode.free_field
    end
  end

  describe "convenio barcode (44 digits) round-trip" do
    test "validates and parses a convenio barcode" do
      # First build a valid convenio linha digitável
      linha_digitavel = build_valid_convenio_boleto(
        segment: "6",
        amount: "00000057320",
        company_id: "04810181",
        free_field: "508202041764946728901"
      )

      # Parse to get the barcode
      {:ok, boleto_from_linha} = Brasilex.parse_boleto(linha_digitavel)
      barcode = boleto_from_linha.barcode

      # Validate the barcode directly
      assert :ok = Brasilex.validate_boleto(barcode)

      # Parse the barcode
      {:ok, boleto} = Brasilex.parse_boleto(barcode)
      assert boleto.type == :convenio
      assert boleto.segment == "6"
    end
  end

  # Helper functions to build valid boletos

  defp build_valid_banking_boleto(opts) do
    bank_code = Keyword.fetch!(opts, :bank_code)
    currency = Keyword.fetch!(opts, :currency)
    free_field = Keyword.fetch!(opts, :free_field)
    due_factor = Keyword.fetch!(opts, :due_factor)
    amount = Keyword.fetch!(opts, :amount)

    # Split free field into 3 parts: 5 + 10 + 10
    <<free1::binary-size(5), free2::binary-size(10), free3::binary-size(10)>> = free_field

    # Build field 1: bank(3) + currency(1) + free1(5) + DV
    field1_payload = bank_code <> currency <> free1
    field1_dv = Mod10.calculate(field1_payload)
    field1 = field1_payload <> Integer.to_string(field1_dv)

    # Build field 2: free2(10) + DV
    field2_dv = Mod10.calculate(free2)
    field2 = free2 <> Integer.to_string(field2_dv)

    # Build field 3: free3(10) + DV
    field3_dv = Mod10.calculate(free3)
    field3 = free3 <> Integer.to_string(field3_dv)

    # Field 5: due_factor(4) + amount(10)
    field5 = due_factor <> amount

    # Calculate general DV using Mod11
    # Barcode payload: bank_currency(4) + field5(14) + free_field(25)
    barcode_payload = bank_code <> currency <> field5 <> free_field
    general_dv = Mod11.calculate(barcode_payload)

    # Combine all fields
    field1 <> field2 <> field3 <> Integer.to_string(general_dv) <> field5
  end

  defp build_valid_convenio_boleto(opts) do
    segment = Keyword.fetch!(opts, :segment)
    amount = Keyword.fetch!(opts, :amount)
    company_id = Keyword.fetch!(opts, :company_id)
    free_field = Keyword.fetch!(opts, :free_field)

    # Convenio barcode structure (44 digits):
    # - Position 0: "8" (product ID)
    # - Position 1: segment (identifies service type)
    # - Position 2: value type (determines checksum algorithm: 6,7,8,9 = Mod10)
    # - Position 3: general DV (calculated on positions 0-2 + 4-43)
    # - Positions 4-43: amount + company_id + free_field

    # Use value_type "6" to ensure Mod10 is used
    value_type = "6"

    # Build barcode payload WITHOUT the general DV (43 chars)
    header = "8" <> segment <> value_type  # product + segment + value_type = 3 chars
    rest = amount <> company_id <> free_field  # 11 + 8 + 21 = 40 chars
    barcode_payload = header <> rest  # 43 chars (missing general DV)

    # Calculate general DV using Mod10 (for value_type 6,7,8,9)
    general_dv = Mod10.calculate(barcode_payload)

    # Insert general DV at position 3
    <<prefix::binary-size(3), suffix::binary>> = barcode_payload
    full_barcode = prefix <> Integer.to_string(general_dv) <> suffix  # 44 chars

    # Split barcode into 4 parts of 11 chars each
    parts = for i <- 0..3, do: binary_part(full_barcode, i * 11, 11)

    # Add field DV to each part (using Mod10 for value_type 6,7,8,9)
    fields = Enum.map(parts, fn part ->
      dv = Mod10.calculate(part)
      part <> Integer.to_string(dv)
    end)

    Enum.join(fields)
  end

  defp format_banking_linha_digitavel(linha) do
    # Format: XXXXX.XXXXX XXXXX.XXXXXX XXXXX.XXXXXX X XXXXXXXXXXXXXX
    <<f1::binary-size(5), f2::binary-size(5),
      f3::binary-size(5), f4::binary-size(6),
      f5::binary-size(5), f6::binary-size(6),
      f7::binary-size(1),
      f8::binary-size(14)>> = linha

    "#{f1}.#{f2} #{f3}.#{f4} #{f5}.#{f6} #{f7} #{f8}"
  end
end
