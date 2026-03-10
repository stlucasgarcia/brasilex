defmodule Brasilex.Boleto.Banking.Parser do
  @moduledoc false
  # Parses boleto bancário linha digitável (47 digits) and barcode (44 digits)
  # into a Boleto struct.

  alias Brasilex.Boleto

  # FEBRABAN reset the due-date factor cycle on 2025-02-22.
  # Factors 0001-0999 only exist in the legacy cycle, while 1000+ is ambiguous
  # between pre-reset and post-reset boletos. Brasilex keeps parsing deterministic
  # by interpreting 1000+ with the post-reset base.
  @legacy_base_date ~D[1997-10-07]
  @current_cycle_base_date ~D[2022-05-29]
  @current_cycle_first_factor 1000

  @doc """
  Parses a validated 47-digit linha digitável into a Boleto struct.
  """
  @spec parse(String.t()) :: {:ok, Boleto.t()}
  def parse(
        <<
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
        >> = raw
      ) do
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

  defp parse_amount(amount) do
    amount
    |> String.to_integer()
    |> Decimal.new()
    |> Decimal.div(100)
  end

  # Parses due date from 4-digit factor
  # Factor is the number of days since base date
  # Returns nil if factor is "0000" (means "no due date")
  #
  # FEBRABAN rollover (2025-02-22):
  # - Legacy cycle: base 1997-10-07, factor 0999 = 2000-07-02
  # - Current cycle: base 2022-05-29, factor 1000 = 2025-02-22
  #
  # Factors 1000-9999 are ambiguous if you need to reconstruct a pre-reset
  # boleto exactly. This parser chooses the current cycle consistently so the
  # same input never changes meaning over time.
  defp parse_due_date("0000"), do: nil

  defp parse_due_date(factor) do
    case String.to_integer(factor) do
      days when days < @current_cycle_first_factor ->
        Date.add(@legacy_base_date, days)

      days ->
        Date.add(@current_cycle_base_date, days)
    end
  end

  @doc """
  Parses a validated 44-digit banking barcode into a Boleto struct.
  """
  @spec parse_barcode(String.t()) :: {:ok, Boleto.t()}
  def parse_barcode(
        <<
          bank_code::binary-size(3),
          currency::binary-size(1),
          _dv::binary-size(1),
          due_factor::binary-size(4),
          amount::binary-size(10),
          free_field::binary-size(25)
        >> = barcode
      ) do
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
