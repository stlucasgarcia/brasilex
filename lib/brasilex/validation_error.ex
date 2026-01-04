defmodule Brasilex.ValidationError do
  @moduledoc """
  Exception raised when validation fails.

  ## Fields

    * `:reason` - The validation error atom or tuple
    * `:message` - Human-readable error message

  ## Error Reasons

  ### Boleto
    * `:invalid_length` - Wrong number of digits
    * `:invalid_format` - Contains invalid characters
    * `:invalid_checksum` - Check digit validation failed
    * `{:invalid_field_checksum, n}` - Field n check digit validation failed
    * `:unknown_type` - Could not determine boleto type

  ### State Registration (IE)
    * `:invalid_length` - Wrong number of digits (expected 9-14)
    * `:invalid_format` - Contains invalid characters
    * `:invalid_checksum` - Check digit validation failed

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
    "Invalid length: wrong number of digits"
  end

  defp format_message(:invalid_format) do
    "Invalid format: contains invalid characters"
  end

  defp format_message(:invalid_checksum) do
    "Invalid check digit"
  end

  defp format_message({:invalid_field_checksum, field_num}) do
    "Invalid check digit in field #{field_num}"
  end

  defp format_message(:unknown_type) do
    "Unknown type: could not identify document type"
  end

  defp format_message(reason) do
    "Validation failed: #{inspect(reason)}"
  end
end
