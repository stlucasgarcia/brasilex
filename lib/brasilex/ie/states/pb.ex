defmodule Brasilex.IE.States.PB do
  @moduledoc false
  # Validates Paraíba (PB) State Registration.
  #
  # Format: 9 digits (8 base + 1 check digit)
  #
  # Algorithm: Mod11 with weights 9-2
  # If result is 10 or 11, digit is 0
  # Otherwise digit is 11 - remainder
  #
  # Example: 06000001-5

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Paraíba IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(8), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in PB format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end
end
