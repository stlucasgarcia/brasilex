defmodule Brasilex.Boleto do
  @moduledoc """
  Represents a parsed Brazilian boleto (bank slip).

  ## Fields

    * `:type` - Either `:banking` (bank collection) or `:convenio` (utility/tax)
    * `:raw` - Original linha digitável string (sanitized, digits only)
    * `:barcode` - 44-digit barcode representation
    * `:bank_code` - 3-digit bank code (banking boletos only)
    * `:currency_code` - Currency indicator (banking: "9" = BRL)
    * `:amount` - Amount in reais (Decimal) or nil if not specified
    * `:due_date` - Due date as `Date` or nil if not specified
    * `:segment` - Segment identifier (convenio boletos only)
    * `:company_id` - Company/CNPJ identifier (convenio boletos only)
    * `:free_field` - Bank-defined or company-defined content

  ## Examples

      iex> boleto = %Brasilex.Boleto{
      ...>   type: :banking,
      ...>   raw: "23793381286000000000300000000400184340000019900",
      ...>   barcode: "23791843400000199003381260000000000000000040",
      ...>   bank_code: "237",
      ...>   currency_code: "9",
      ...>   amount: Decimal.new("199.00"),
      ...>   due_date: ~D[2020-07-04],
      ...>   free_field: "3381260000000000000000004"
      ...> }
      iex> Brasilex.Boleto.banking?(boleto)
      true

  """

  alias Brasilex.Boleto.Parser
  alias Brasilex.Boleto.Validator
  alias Brasilex.ValidationError

  @type boleto_type :: :banking | :convenio

  @type validation_error ::
          :invalid_length
          | :invalid_format
          | :invalid_checksum
          | {:invalid_field_checksum, pos_integer()}
          | :unknown_type

  @type t :: %__MODULE__{
          type: boleto_type(),
          raw: String.t(),
          barcode: String.t(),
          bank_code: String.t() | nil,
          currency_code: String.t() | nil,
          amount: Decimal.t() | nil,
          due_date: Date.t() | nil,
          segment: String.t() | nil,
          company_id: String.t() | nil,
          free_field: String.t()
        }

  @enforce_keys [:type, :raw, :barcode, :free_field]
  defstruct [
    :type,
    :raw,
    :barcode,
    :bank_code,
    :currency_code,
    :amount,
    :due_date,
    :segment,
    :company_id,
    :free_field
  ]

  @doc """
  Validates a boleto linha digitável or barcode.

  Accepts both formats:
  - Linha digitável: 47 digits (banking) or 48 digits (convenio)
  - Barcode: 44 digits

  Returns `:ok` if valid, or `{:error, reason}` if invalid.

  ## Examples

      iex> Brasilex.Boleto.validate("12345")
      {:error, :invalid_length}

      iex> Brasilex.Boleto.validate("")
      {:error, :invalid_format}

  ## Error Reasons

    * `:invalid_length` - Wrong number of digits (expected 44, 47, or 48)
    * `:invalid_format` - Contains non-digit characters
    * `:invalid_checksum` - General check digit validation failed
    * `{:invalid_field_checksum, n}` - Field n check digit validation failed
    * `:unknown_type` - Could not determine boleto type

  """
  @spec validate(String.t()) :: :ok | {:error, validation_error()}
  def validate(input) when is_binary(input) do
    Validator.validate(input)
  end

  @doc """
  Same as `validate/1` but raises `Brasilex.ValidationError` on error.

  ## Examples

      iex> Brasilex.Boleto.validate!("12345")
      ** (Brasilex.ValidationError) Invalid length: wrong number of digits

  """
  @spec validate!(String.t()) :: :ok
  def validate!(input) when is_binary(input) do
    case validate(input) do
      :ok -> :ok
      {:error, reason} -> raise ValidationError, reason: reason
    end
  end

  @doc """
  Parses a boleto linha digitável or barcode into a structured `Brasilex.Boleto`.

  Accepts both formats:
  - Linha digitável: 47 digits (banking) or 48 digits (convenio)
  - Barcode: 44 digits

  Validates the input before parsing. Returns `{:ok, boleto}` on success
  or `{:error, reason}` on failure.

  ## Examples

      iex> Brasilex.Boleto.parse("12345")
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
  @spec parse(String.t()) :: {:ok, t()} | {:error, validation_error()}
  def parse(input) when is_binary(input) do
    Parser.parse(input)
  end

  @doc """
  Same as `parse/1` but raises `Brasilex.ValidationError` on error.

  ## Examples

      iex> Brasilex.Boleto.parse!("12345")
      ** (Brasilex.ValidationError) Invalid length: wrong number of digits

  """
  @spec parse!(String.t()) :: t()
  def parse!(input) when is_binary(input) do
    case parse(input) do
      {:ok, boleto} -> boleto
      {:error, reason} -> raise ValidationError, reason: reason
    end
  end

  @doc """
  Returns true if this is a bank collection boleto (47 digits).

  ## Examples

      iex> boleto = %Brasilex.Boleto{type: :banking, raw: "", barcode: "", free_field: ""}
      iex> Brasilex.Boleto.banking?(boleto)
      true

      iex> boleto = %Brasilex.Boleto{type: :convenio, raw: "", barcode: "", free_field: ""}
      iex> Brasilex.Boleto.banking?(boleto)
      false

  """
  @spec banking?(t()) :: boolean()
  def banking?(%__MODULE__{type: :banking}), do: true
  def banking?(%__MODULE__{}), do: false

  @doc """
  Returns true if this is a utility/tax boleto (48 digits).

  ## Examples

      iex> boleto = %Brasilex.Boleto{type: :convenio, raw: "", barcode: "", free_field: ""}
      iex> Brasilex.Boleto.convenio?(boleto)
      true

      iex> boleto = %Brasilex.Boleto{type: :banking, raw: "", barcode: "", free_field: ""}
      iex> Brasilex.Boleto.convenio?(boleto)
      false

  """
  @spec convenio?(t()) :: boolean()
  def convenio?(%__MODULE__{type: :convenio}), do: true
  def convenio?(%__MODULE__{}), do: false
end
