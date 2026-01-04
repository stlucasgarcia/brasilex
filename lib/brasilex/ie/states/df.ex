defmodule Brasilex.IE.States.DF do
  @moduledoc false
  # Validates Distrito Federal (DF) State Registration.
  #
  # Format: 13 digits (11 base + 2 check digits)
  # Structure: 07 + 6 sequential + 3 branch (001=matriz) + DD
  # Mask: 07.NNNNNN.NNN-DD
  #
  # Algorithm: Mod11 with weights 2-9 sequence (right to left)
  # D1: weights 4,3,2,9,8,7,6,5,4,3,2 on first 11 digits
  # D2: weights 5,4,3,2,9,8,7,6,5,4,3,2 on first 12 digits (including D1)
  # If result is 10 or 11, digit is 0
  #
  # Example: 07.300001.001-09

  @weights_d1 [4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  @weights_d2 [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Distrito Federal IE number (13 digits, prefix "07").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"07", _rest::binary>> = digits) when byte_size(digits) == 13 do
    if valid_checksum?(digits), do: :ok, else: {:error, :invalid_checksum}
  end

  def validate(digits) when byte_size(digits) == 13, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  defp valid_checksum?(<<payload::binary-size(11), d1::binary-size(1), d2::binary-size(1)>>) do
    calculated_d1 = calculate_digit(payload, @weights_d1)

    if String.to_integer(d1) != calculated_d1 do
      false
    else
      payload_d2 = payload <> d1
      calculated_d2 = calculate_digit(payload_d2, @weights_d2)
      String.to_integer(d2) == calculated_d2
    end
  end

  defp calculate_digit(payload, weights) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(weights)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    remainder = rem(sum, 11)
    result = 11 - remainder

    if result in [10, 11], do: 0, else: result
  end

  @doc """
  Formats an IE number in DF format: NN.NNNNNN.NNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(6), c::binary-size(3), d::binary-size(2)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end

  def format(digits), do: digits
end
