defmodule Brasilex.Boleto.Validator do
  @moduledoc false
  # Internal module for validation dispatch.
  #
  # Owns sanitization, type detection, and per-type validation routing.
  # `Brasilex.Boleto.Parser` calls `validate_typed/1` to reuse the
  # detection and validation work before parsing.
  #
  # Supports both linha digitável (47/48 digits) and barcode (44 digits).

  alias Brasilex.Boleto.{Banking, Convenio}

  @type type :: :banking | :convenio
  @type format :: :linha_digitavel | :barcode

  @doc """
  Validates a linha digitável or barcode.
  """
  @spec validate(String.t()) :: :ok | {:error, atom() | tuple()}
  def validate(input) do
    with {:ok, _type, _format, _digits} <- validate_typed(input), do: :ok
  end

  @doc """
  Validates and returns the detected type, format, and sanitized digits.

  Used by `Brasilex.Boleto.Parser` so parsing reuses the validation pass
  rather than re-detecting type and re-running checksum verification.
  """
  @spec validate_typed(String.t()) ::
          {:ok, type(), format(), String.t()} | {:error, atom() | tuple()}
  def validate_typed(input) do
    with {:ok, digits} <- sanitize(input),
         {:ok, type, format} <- detect_type(digits),
         :ok <- validate_digits(type, format, digits) do
      {:ok, type, format, digits}
    end
  end

  @doc """
  Removes formatting characters, keeping only digits.

  Accepts input with common formatting:
  - Dots: "23793.38128"
  - Spaces: "23793 38128"
  - Hyphens: "23793-38128"
  """
  @spec sanitize(String.t()) :: {:ok, String.t()} | {:error, :invalid_format | :invalid_length}
  def sanitize(input) when is_binary(input) do
    if String.match?(input, ~r/^[0-9.\-\s]+$/) do
      digits = String.replace(input, ~r/[\.\-\s]/, "")
      length = String.length(digits)

      cond do
        length == 0 -> {:error, :invalid_format}
        length in [44, 47, 48] -> {:ok, digits}
        true -> {:error, :invalid_length}
      end
    else
      {:error, :invalid_format}
    end
  end

  @doc """
  Detects boleto type and format based on length and first digit.

  Returns `{:ok, type, format}` where:
  - type: `:banking` or `:convenio`
  - format: `:linha_digitavel` or `:barcode`

  Detection rules:
  - 44 digits starting with "8": Convenio barcode
  - 44 digits (other): Banking barcode
  - 47 digits: Banking linha digitável
  - 48 digits starting with "8": Convenio linha digitável
  """
  @spec detect_type(String.t()) :: {:ok, type(), format()} | {:error, :unknown_type}
  def detect_type(<<first::binary-size(1), _rest::binary>> = digits) do
    case {String.length(digits), first} do
      {44, "8"} -> {:ok, :convenio, :barcode}
      {44, _} -> {:ok, :banking, :barcode}
      {47, _} -> {:ok, :banking, :linha_digitavel}
      {48, "8"} -> {:ok, :convenio, :linha_digitavel}
      _ -> {:error, :unknown_type}
    end
  end

  def detect_type(_), do: {:error, :unknown_type}

  defp validate_digits(:banking, :linha_digitavel, digits),
    do: Banking.Validator.validate(digits)

  defp validate_digits(:banking, :barcode, digits),
    do: Banking.Validator.validate_barcode(digits)

  defp validate_digits(:convenio, :linha_digitavel, digits),
    do: Convenio.Validator.validate(digits)

  defp validate_digits(:convenio, :barcode, digits),
    do: Convenio.Validator.validate_barcode(digits)
end
