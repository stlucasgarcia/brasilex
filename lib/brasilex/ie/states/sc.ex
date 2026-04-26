defmodule Brasilex.IE.States.SC do
  @moduledoc false
  # Validates Santa Catarina (SC) State Registration.
  #
  # Format: 9 digits
  # Check digit: position 9 (Mod11 with weights 9,8,7,6,5,4,3,2)
  #
  # Example: 251.040.852
  # Calculation:
  #   (2*9) + (5*8) + (1*7) + (0*6) + (4*5) + (0*4) + (8*3) + (5*2) = 119
  #   119 mod 11 = 9
  #   11 - 9 = 2 (check digit)

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Santa Catarina IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(8), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in SC format: NNN.NNN.NNN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(3), b::binary-size(3), c::binary-size(3)>>) do
    "#{a}.#{b}.#{c}"
  end
end
