defmodule Brasilex.ValidationError do
  @moduledoc """
  Exception raised when boleto validation fails.

  ## Fields

    * `:reason` - The validation error atom or tuple
    * `:message` - Human-readable error message

  ## Error Reasons

    * `:invalid_length` - Linha digitável has wrong number of digits
    * `:invalid_format` - Input contains non-digit characters after sanitization
    * `:invalid_checksum` - General check digit validation failed
    * `{:invalid_field_checksum, n}` - Field n (1-4) check digit validation failed
    * `:unknown_type` - Could not determine boleto type from input

  """

  defexception [:reason, :message]

  @type reason ::
          :invalid_length
          | :invalid_format
          | :invalid_checksum
          | {:invalid_field_checksum, pos_integer()}
          | :unknown_type

  @type t :: %__MODULE__{
          reason: reason(),
          message: String.t()
        }

  @impl true
  @spec exception(keyword()) :: t()
  def exception(opts) do
    reason = Keyword.fetch!(opts, :reason)
    message = format_message(reason)
    %__MODULE__{reason: reason, message: message}
  end

  defp format_message(:invalid_length) do
    "Invalid linha digitável length: expected 47 or 48 digits"
  end

  defp format_message(:invalid_format) do
    "Invalid format: linha digitável must contain only digits"
  end

  defp format_message(:invalid_checksum) do
    "Invalid general check digit"
  end

  defp format_message({:invalid_field_checksum, field_num}) do
    "Invalid check digit in field #{field_num}"
  end

  defp format_message(:unknown_type) do
    "Unknown boleto type: could not identify as banking or convenio"
  end

  defp format_message(reason) do
    "Validation failed: #{inspect(reason)}"
  end
end
