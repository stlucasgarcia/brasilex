defmodule Brasilex.IE.States.RO do
  @moduledoc false
  # Validates Rondônia (RO) State Registration.
  #
  # Format: 14 digits (current) or 9 digits (legacy before 01/08/2000)
  #
  # Current format (14 digits): 13 enterprise digits + 1 check digit
  # Weights: 6,5,4,3,2,9,8,7,6,5,4,3,2
  #
  # Legacy format (9 digits): 3 municipality + 5 enterprise + 1 check digit
  # Only the 5 enterprise digits are used, with weights 6,5,4,3,2
  #
  # Example 14 digits: 0000000062521-3
  # Calculation:
  #   (0*6)+(0*5)+(0*4)+(0*3)+(0*2)+(0*9)+(0*8)+(0*7)+(6*6)+(2*5)+(5*4)+(2*3)+(1*2) = 74
  #   74 mod 11 = 8
  #   11 - 8 = 3 (check digit)
  #
  # If result is 10 or 11, subtract 10 to get the digit

  alias Brasilex.IE.Checksum

  @weights_14 [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  @weights_9 [6, 5, 4, 3, 2]

  @doc """
  Validates a Rondônia IE number (14 or 9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(13), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights_14, :subtract_10_when_gt_9),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(<<_municipality::binary-size(3), enterprise::binary-size(5), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(enterprise, @weights_9, :subtract_10_when_gt_9),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in RO format.
  14 digits: NNNNNNNNNNNNN-N
  9 digits (legacy): NNN.NNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(13), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end

  def format(<<mun::binary-size(3), ent::binary-size(5), dv::binary-size(1)>>) do
    "#{mun}.#{ent}-#{dv}"
  end
end
