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

  @weights_14 [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  @weights_9 [6, 5, 4, 3, 2]

  @doc """
  Validates a Rondônia IE number (14 or 9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 14 do
    if valid_checksum_14?(digits) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  def validate(digits) when byte_size(digits) == 9 do
    if valid_checksum_9?(digits) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  def validate(_), do: {:error, :invalid_length}

  defp valid_checksum_14?(<<payload::binary-size(13), dv::binary-size(1)>>) do
    calculated = calculate_dv(payload, @weights_14)
    String.to_integer(dv) == calculated
  end

  defp valid_checksum_9?(<<_municipality::binary-size(3), enterprise::binary-size(5), dv::binary-size(1)>>) do
    calculated = calculate_dv(enterprise, @weights_9)
    String.to_integer(dv) == calculated
  end

  defp calculate_dv(payload, weights) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(weights)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    remainder = rem(sum, 11)
    result = 11 - remainder

    if result in [10, 11], do: result - 10, else: result
  end

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

  def format(digits), do: digits
end
