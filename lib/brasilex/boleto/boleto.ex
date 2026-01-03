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

  @type boleto_type :: :banking | :convenio

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
