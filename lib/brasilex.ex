defmodule Brasilex do
  @moduledoc """
  Brazilian boleto (bank slip) parser and validator.

  Brasilex provides functions to validate and parse Brazilian boletos,
  supporting both the "linha digitável" (typeable line) and barcode formats.

  ## Supported Boleto Types

    * **Banking Boleto** - Bank collection boletos
      - Linha digitável: 47 digits
      - Barcode: 44 digits
    * **Convenio Boleto** - Utility/tax boletos (starting with "8")
      - Linha digitável: 48 digits
      - Barcode: 44 digits

  ## Usage

      # Validate a boleto (linha digitável)
      Brasilex.validate_boleto("23793.38128 60000.000003 00000.000400 1 84340000019900")
      #=> :ok

      # Validate a barcode (44 digits)
      Brasilex.validate_boleto("23791843400000199003812860000000003000000004")
      #=> :ok

      # Parse a boleto
      {:ok, boleto} = Brasilex.parse_boleto("23793.38128 60000.000003 00000.000400 1 84340000019900")
      boleto.bank_code
      #=> "237"

  ## Input Formats

  Both linha digitável and barcode can be provided with or without formatting:

      # Linha digitável with formatting (dots, spaces, hyphens)
      "23793.38128 60000.000003 00000.000400 1 84340000019900"

      # Linha digitável without formatting (47 or 48 digits)
      "23793381286000000000300000000400184340000019900"

      # Barcode (44 digits)
      "23791843400000199003812860000000003000000004"

  ## Error Handling

  All functions return `{:ok, result}` or `{:error, reason}` tuples,
  making them pipe-friendly and composable. Bang variants (`!`) are
  provided for convenience when exceptions are preferred.
  """

  alias Brasilex.Boleto
  alias Brasilex.Boleto.{Parser, Validator}
  alias Brasilex.ValidationError

  @type linha_digitavel :: String.t()

  @type validation_error ::
          :invalid_length
          | :invalid_format
          | :invalid_checksum
          | {:invalid_field_checksum, pos_integer()}
          | :unknown_type

  @doc """
  Validates a boleto linha digitável or barcode.

  Accepts both formats:
  - Linha digitável: 47 digits (banking) or 48 digits (convenio)
  - Barcode: 44 digits

  Returns `:ok` if valid, or `{:error, reason}` if invalid.

  ## Examples

      iex> Brasilex.validate_boleto("12345")
      {:error, :invalid_length}

      iex> Brasilex.validate_boleto("")
      {:error, :invalid_format}

  ## Error Reasons

    * `:invalid_length` - Wrong number of digits (expected 44, 47, or 48)
    * `:invalid_format` - Contains non-digit characters
    * `:invalid_checksum` - General check digit validation failed
    * `{:invalid_field_checksum, n}` - Field n check digit validation failed
    * `:unknown_type` - Could not determine boleto type

  """
  @spec validate_boleto(linha_digitavel()) :: :ok | {:error, validation_error()}
  def validate_boleto(input) when is_binary(input) do
    Validator.validate(input)
  end

  @doc """
  Parses a boleto linha digitável or barcode into a structured `Brasilex.Boleto`.

  Accepts both formats:
  - Linha digitável: 47 digits (banking) or 48 digits (convenio)
  - Barcode: 44 digits

  Validates the input before parsing. Returns `{:ok, boleto}` on success
  or `{:error, reason}` on failure.

  ## Examples

      iex> Brasilex.parse_boleto("12345")
      {:error, :invalid_length}

  ## Parsed Fields

  For **banking boletos** (47-digit linha digitável or 44-digit barcode):
    * `:bank_code` - 3-digit bank code
    * `:currency_code` - Currency indicator ("9" = BRL)
    * `:amount` - Amount in reais as float (or nil if "any amount")
    * `:due_date` - Due date (or nil if "no due date")
    * `:free_field` - Bank-defined content (25 digits)

  For **convenio boletos** (48-digit linha digitável or 44-digit barcode starting with "8"):
    * `:segment` - Segment identifier
    * `:amount` - Amount in reais as float (or nil)
    * `:company_id` - Company/CNPJ identifier
    * `:free_field` - Segment-specific content

  """
  @spec parse_boleto(linha_digitavel()) :: {:ok, Boleto.t()} | {:error, validation_error()}
  def parse_boleto(input) when is_binary(input) do
    Parser.parse(input)
  end

  @doc """
  Same as `validate_boleto/1` but raises `Brasilex.ValidationError` on error.

  ## Examples

      iex> Brasilex.validate_boleto!("12345")
      ** (Brasilex.ValidationError) Invalid linha digitável length: expected 47 or 48 digits

  """
  @spec validate_boleto!(linha_digitavel()) :: :ok
  def validate_boleto!(linha_digitavel) do
    case validate_boleto(linha_digitavel) do
      :ok -> :ok
      {:error, reason} -> raise ValidationError, reason: reason
    end
  end

  @doc """
  Same as `parse_boleto/1` but raises `Brasilex.ValidationError` on error.

  ## Examples

      iex> Brasilex.parse_boleto!("12345")
      ** (Brasilex.ValidationError) Invalid linha digitável length: expected 47 or 48 digits

  """
  @spec parse_boleto!(linha_digitavel()) :: Boleto.t()
  def parse_boleto!(linha_digitavel) do
    case parse_boleto(linha_digitavel) do
      {:ok, boleto} -> boleto
      {:error, reason} -> raise ValidationError, reason: reason
    end
  end
end
