defmodule Brasilex.Boleto.Parser do
  @moduledoc false
  # Internal module for parsing dispatch.
  #
  # Reuses `Brasilex.Boleto.Validator.validate_typed/1` for sanitization,
  # type detection, and validation, then dispatches to the appropriate
  # per-type parser.
  #
  # Supports both linha digitável (47/48 digits) and barcode (44 digits).

  alias Brasilex.Boleto
  alias Brasilex.Boleto.{Banking, Convenio, Validator}

  @doc """
  Parses a linha digitável or barcode into a Boleto struct.
  """
  @spec parse(String.t()) :: {:ok, Boleto.t()} | {:error, atom() | tuple()}
  def parse(input) do
    with {:ok, type, format, digits} <- Validator.validate_typed(input) do
      parse_digits(type, format, digits)
    end
  end

  defp parse_digits(:banking, :linha_digitavel, digits), do: Banking.Parser.parse(digits)
  defp parse_digits(:banking, :barcode, digits), do: Banking.Parser.parse_barcode(digits)
  defp parse_digits(:convenio, :linha_digitavel, digits), do: Convenio.Parser.parse(digits)
  defp parse_digits(:convenio, :barcode, digits), do: Convenio.Parser.parse_barcode(digits)
end
