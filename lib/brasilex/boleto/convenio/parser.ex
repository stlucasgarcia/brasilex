defmodule Brasilex.Boleto.Convenio.Parser do
  @moduledoc false
  # Parses boleto de convênio linha digitável (48 digits) and barcode (44 digits)
  # into a Boleto struct.
  #
  # Convenio boletos are used for utility bills, taxes, and other
  # government/company collections. They have a different structure
  # than banking boletos.

  alias Brasilex.Boleto

  @doc """
  Parses a validated 48-digit linha digitável into a Boleto struct.
  """
  @spec parse(String.t()) :: {:ok, Boleto.t()}
  def parse(<<"8", segment::binary-size(1), _rest::binary>> = raw)
      when byte_size(raw) == 48 do
    # Extract barcode first, then parse fields from the barcode
    # (linha digitável has field DVs that break up the content)
    barcode = extract_barcode(raw)

    boleto = %Boleto{
      type: :convenio,
      raw: raw,
      barcode: barcode,
      segment: segment,
      amount: parse_amount(barcode),
      company_id: extract_company_id(barcode),
      free_field: extract_free_field(barcode)
    }

    {:ok, boleto}
  end

  # Extracts the 44-digit barcode from linha digitável
  # by removing the check digits from each field
  defp extract_barcode(digits) do
    for i <- 0..3, into: "" do
      binary_part(digits, i * 12, 11)
    end
  end

  # Parses amount from barcode positions 4-14 (11 digits) and converts to reais
  defp parse_amount(<<_header::binary-size(4), amount::binary-size(11), _::binary>>) do
    case String.to_integer(amount) do
      0 -> nil
      centavos -> centavos / 100
    end
  end

  # Extracts company identifier from barcode positions 15-22 (8 digits)
  defp extract_company_id(<<_::binary-size(15), company::binary-size(8), _::binary>>) do
    company
  end

  # Extracts free field from barcode (positions 23-43)
  defp extract_free_field(<<_::binary-size(23), free_field::binary>>) do
    free_field
  end

  @doc """
  Parses a validated 44-digit convenio barcode into a Boleto struct.
  """
  @spec parse_barcode(String.t()) :: {:ok, Boleto.t()}
  def parse_barcode(<<"8", segment::binary-size(1), _rest::binary>> = barcode)
      when byte_size(barcode) == 44 do
    boleto = %Boleto{
      type: :convenio,
      raw: barcode,
      barcode: barcode,
      segment: segment,
      amount: parse_amount(barcode),
      company_id: extract_company_id(barcode),
      free_field: extract_free_field(barcode)
    }

    {:ok, boleto}
  end
end
