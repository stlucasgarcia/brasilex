defmodule Brasilex.Boleto.Banking.Parser do
  @moduledoc false
  # Parses boleto bancário linha digitável (47 digits) and barcode (44 digits)
  # into a Boleto struct.

  alias Brasilex.Boleto

  # Base date for due date factor calculation (FEBRABAN specification)
  @base_date ~D[1997-10-07]

  @doc """
  Parses a validated 47-digit linha digitável into a Boleto struct.
  """
  @spec parse(String.t()) :: {:ok, Boleto.t()}
  def parse(<<
        bank_code::binary-size(3),
        currency::binary-size(1),
        free1::binary-size(5),
        _dv1::binary-size(1),
        free2::binary-size(10),
        _dv2::binary-size(1),
        free3::binary-size(10),
        _dv3::binary-size(1),
        _general_dv::binary-size(1),
        due_factor::binary-size(4),
        amount::binary-size(10)
      >> = raw) do
    barcode = build_barcode(raw)

    boleto = %Boleto{
      type: :banking,
      raw: raw,
      barcode: barcode,
      bank_code: bank_code,
      currency_code: currency,
      amount: parse_amount(amount),
      due_date: parse_due_date(due_factor),
      free_field: free1 <> free2 <> free3
    }

    {:ok, boleto}
  end

  # Builds the 44-digit barcode from linha digitável
  defp build_barcode(<<
         field1::binary-size(10),
         field2::binary-size(11),
         field3::binary-size(11),
         general_dv::binary-size(1),
         field5::binary-size(14)
       >>) do
    <<bank_currency::binary-size(4), free1::binary-size(5), _dv1::binary-size(1)>> = field1
    <<free2::binary-size(10), _dv2::binary-size(1)>> = field2
    <<free3::binary-size(10), _dv3::binary-size(1)>> = field3

    # Barcode: [bank_currency(4)][general_dv(1)][due_factor_amount(14)][free_field(25)]
    bank_currency <> general_dv <> field5 <> free1 <> free2 <> free3
  end

  # Parses amount from 10-digit string (in centavos) and converts to reais
  # Returns nil if amount is zero (means "any amount")
  defp parse_amount("0000000000"), do: nil
  defp parse_amount(amount), do: String.to_integer(amount) / 100

  # Parses due date from 4-digit factor
  # Factor is the number of days since base date (1997-10-07)
  # Returns nil if factor is "0000" (means "no due date")
  defp parse_due_date("0000"), do: nil

  defp parse_due_date(factor) do
    days = String.to_integer(factor)
    Date.add(@base_date, days)
  end

  @doc """
  Parses a validated 44-digit banking barcode into a Boleto struct.
  """
  @spec parse_barcode(String.t()) :: {:ok, Boleto.t()}
  def parse_barcode(<<
        bank_code::binary-size(3),
        currency::binary-size(1),
        _dv::binary-size(1),
        due_factor::binary-size(4),
        amount::binary-size(10),
        free_field::binary-size(25)
      >> = barcode) do
    boleto = %Boleto{
      type: :banking,
      raw: barcode,
      barcode: barcode,
      bank_code: bank_code,
      currency_code: currency,
      amount: parse_amount(amount),
      due_date: parse_due_date(due_factor),
      free_field: free_field
    }

    {:ok, boleto}
  end
end
