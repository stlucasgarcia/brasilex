defmodule Brasilex.IE.States.CE do
  @moduledoc false
  # Validates Ceará (CE) State Registration.
  #
  # Format: 9 digits (8 base + 1 check digit)
  # Prefix: Often starts with "06" but not required
  #
  # Algorithm: Mod11 with weights 9-2
  # If remainder is 0 or 1, digit is 0
  # Otherwise digit is 11 - remainder
  #
  # Example: 06000001-5

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Ceará IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(8), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in CE format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end
end
