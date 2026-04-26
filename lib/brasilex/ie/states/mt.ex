defmodule Brasilex.IE.States.MT do
  @moduledoc false
  # Validates Mato Grosso (MT) State Registration.
  #
  # Format: 11 digits (10 digits + 1 check digit)
  # Weights: 3,2,9,8,7,6,5,4,3,2 (Mod11 cycling 2-9, then 2-3)
  #
  # Example: 0013000001-9
  # Calculation:
  #   (0*3)+(0*2)+(1*9)+(3*8)+(0*7)+(0*6)+(0*5)+(0*4)+(0*3)+(1*2) = 35
  #   35 mod 11 = 2
  #   11 - 2 = 9 (check digit)
  #
  # If remainder is 0 or 1, digit = 0

  alias Brasilex.IE.Checksum

  @weights [3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Mato Grosso IE number (11 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(10), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in MT format: NNNNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(10), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end
end
