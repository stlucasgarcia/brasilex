defmodule Brasilex.IE.States.SE do
  @moduledoc false
  # Validates Sergipe (SE) State Registration.
  #
  # Format: 9 digits
  # Check digit: position 9 (Mod11 with weights 9,8,7,6,5,4,3,2)
  #
  # Example: 27123456-3
  # Calculation:
  #   (2*9) + (7*8) + (1*7) + (2*6) + (3*5) + (4*4) + (5*3) + (6*2) = 151
  #   151 mod 11 = 8
  #   11 - 8 = 3 (check digit)

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Sergipe IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(8), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in SE format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end
end
