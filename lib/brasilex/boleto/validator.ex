defmodule Brasilex.Boleto.Validator do
  @moduledoc false
  # Internal module for validation dispatch.
  #
  # Handles sanitization, type detection, and routing to the
  # appropriate validator (Banking or Convenio).
  #
  # Supports both linha digitável (47/48 digits) and barcode (44 digits).

  alias Brasilex.Boleto.{Banking, Convenio}

  @doc """
  Validates a linha digitável or barcode, dispatching to the appropriate validator.
  """
  @spec validate(String.t()) :: :ok | {:error, atom() | tuple()}
  def validate(input) do
    with {:ok, digits} <- sanitize(input),
         {:ok, type, format} <- detect_type(digits) do
      case {type, format} do
        {:banking, :linha_digitavel} -> Banking.Validator.validate(digits)
        {:banking, :barcode} -> Banking.Validator.validate_barcode(digits)
        {:convenio, :linha_digitavel} -> Convenio.Validator.validate(digits)
        {:convenio, :barcode} -> Convenio.Validator.validate_barcode(digits)
      end
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
    digits = String.replace(input, ~r/[^0-9]/, "")
    length = String.length(digits)

    cond do
      length == 0 ->
        {:error, :invalid_format}

      length not in [44, 47, 48] ->
        {:error, :invalid_length}

      true ->
        {:ok, digits}
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
  @spec detect_type(String.t()) ::
          {:ok, :banking | :convenio, :linha_digitavel | :barcode} | {:error, :unknown_type}
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
end
