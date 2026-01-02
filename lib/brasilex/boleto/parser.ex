defmodule Brasilex.Boleto.Parser do
  @moduledoc false
  # Internal module for parsing dispatch.
  #
  # Validates input first, then routes to the appropriate
  # parser (Banking or Convenio) to build the Boleto struct.
  #
  # Supports both linha digitável (47/48 digits) and barcode (44 digits).

  alias Brasilex.Boleto
  alias Brasilex.Boleto.{Banking, Convenio, Validator}

  @doc """
  Parses a linha digitável or barcode into a Boleto struct.

  Validates the input before parsing. Returns `{:ok, boleto}` on success
  or `{:error, reason}` on failure.
  """
  @spec parse(String.t()) :: {:ok, Boleto.t()} | {:error, atom() | tuple()}
  def parse(input) do
    with {:ok, digits} <- Validator.sanitize(input),
         {:ok, type, format} <- Validator.detect_type(digits),
         :ok <- validate_by_type(type, format, digits) do
      parse_by_type(type, format, digits)
    end
  end

  defp validate_by_type(:banking, :linha_digitavel, digits),
    do: Banking.Validator.validate(digits)

  defp validate_by_type(:banking, :barcode, digits),
    do: Banking.Validator.validate_barcode(digits)

  defp validate_by_type(:convenio, :linha_digitavel, digits),
    do: Convenio.Validator.validate(digits)

  defp validate_by_type(:convenio, :barcode, digits),
    do: Convenio.Validator.validate_barcode(digits)

  defp parse_by_type(:banking, :linha_digitavel, digits),
    do: Banking.Parser.parse(digits)

  defp parse_by_type(:banking, :barcode, digits),
    do: Banking.Parser.parse_barcode(digits)

  defp parse_by_type(:convenio, :linha_digitavel, digits),
    do: Convenio.Parser.parse(digits)

  defp parse_by_type(:convenio, :barcode, digits),
    do: Convenio.Parser.parse_barcode(digits)
end
