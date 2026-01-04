defmodule Brasilex.IE.States.PR do
  @moduledoc false
  # Validates Paraná (PR) State Registration.
  #
  # Format: 10 digits (8 base + 2 check digits)
  # Mask: NNN.NNNNN-DD
  #
  # Algorithm: Mod11 with specific weight sequences
  # D1: weights 3,2,7,6,5,4,3,2 on first 8 digits
  # D2: weights 4,3,2,7,6,5,4,3,2 on first 9 digits (including D1)
  #
  # If result is 10 or 11, digit is 0
  #
  # Example: 123.45678-50

  @weights_d1 [3, 2, 7, 6, 5, 4, 3, 2]
  @weights_d2 [4, 3, 2, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Paraná IE number (10 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 10 do
    if valid_checksum?(digits), do: :ok, else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  defp valid_checksum?(<<payload::binary-size(8), d1::binary-size(1), d2::binary-size(1)>>) do
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
  Formats an IE number in PR format: NNN.NNNNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(3), b::binary-size(5), dv::binary-size(2)>>) do
    "#{a}.#{b}-#{dv}"
  end

  def format(digits), do: digits
end
