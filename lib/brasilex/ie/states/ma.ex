defmodule Brasilex.IE.States.MA do
  @moduledoc false
  # Validates Maranhão (MA) State Registration.
  #
  # Format: 9 digits (8 base + 1 check digit)
  # Prefix: "12" (state code)
  #
  # Algorithm: Mod11 with weights 9-2
  # If remainder is 0 or 1, digit is 0
  # Otherwise digit is 11 - remainder
  #
  # Example: 12000038-5

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Maranhão IE number (9 digits, prefix "12").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"12", _rest::binary>> = digits) when byte_size(digits) == 9 do
    <<payload::binary-size(8), dv::binary-size(1)>> = digits

    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(digits) when byte_size(digits) == 9, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in MA format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end
end
