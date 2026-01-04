defmodule Brasilex.IE.States.SP do
  @moduledoc false
  # Validates São Paulo (SP) State Registration.
  #
  # Regular format: 12 digits
  # Structure: NNNNNNNNXNNY where:
  #   - X = first check digit (position 9)
  #   - Y = second check digit (position 12)
  #
  # Rural producer format: P + 12 digits (13 chars total)
  # Structure: P0MMMSSSSD000 where:
  #   - P = literal letter P
  #   - 0MMMSSSS = 8 digits for D1 calculation
  #   - D = check digit (position 10 counting from P)
  #   - 000 = 3 digits not used in calculation
  #
  # D1 calculation (position 9):
  #   Weights: 1,3,4,5,6,7,8,10 for positions 1-8
  #   Result = rightmost digit of (sum mod 11)
  #
  # D2 calculation (position 12):
  #   Weights: 3,2,10,9,8,7,6,5,4,3,2 for positions 1-11
  #   Result = rightmost digit of (sum mod 11)
  #
  # Example: 110.042.490.114
  # D1: (1*1)+(1*3)+(0*4)+(0*5)+(4*6)+(2*7)+(4*8)+(9*10) = 164
  #     164 mod 11 = 10, rightmost digit = 0 -> D1 = 0
  #
  # D2: (1*3)+(1*2)+(0*10)+(0*9)+(4*8)+(2*7)+(4*6)+(9*5)+(0*4)+(1*3)+(1*2) = 125
  #     125 mod 11 = 4 -> D2 = 4

  @weights_d1 [1, 3, 4, 5, 6, 7, 8, 10]
  @weights_d2 [3, 2, 10, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a São Paulo IE number.
  Accepts 12 digits (regular) or P + 12 digits (rural producer).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"P", digits::binary-size(12)>>) do
    validate_rural(digits)
  end

  def validate(digits) when byte_size(digits) == 12 do
    validate_regular(digits)
  end

  def validate(_), do: {:error, :invalid_length}

  # Regular IE validation (12 digits)
  defp validate_regular(digits) do
    with :ok <- validate_d1_regular(digits) do
      validate_d2_regular(digits)
    end
  end

  # Rural producer IE validation (12 digits after P)
  defp validate_rural(digits) do
    validate_d1_rural(digits)
  end

  # D1 at position 9 for regular format
  defp validate_d1_regular(<<payload::binary-size(8), d1::binary-size(1), _rest::binary>>) do
    calculated = calculate_d1(payload)

    if String.to_integer(d1) == calculated do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  # D2 at position 12 for regular format
  defp validate_d2_regular(<<payload::binary-size(11), d2::binary-size(1)>>) do
    calculated = calculate_d2(payload)

    if String.to_integer(d2) == calculated do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  # D at position 9 for rural format (after P, so position 10 in full string)
  defp validate_d1_rural(<<payload::binary-size(8), d::binary-size(1), _rest::binary>>) do
    calculated = calculate_d1(payload)

    if String.to_integer(d) == calculated do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  defp calculate_d1(payload) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(@weights_d1)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    rem(rem(sum, 11), 10)
  end

  defp calculate_d2(payload) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(@weights_d2)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    rem(rem(sum, 11), 10)
  end

  @doc """
  Formats an IE number in SP format.
  Regular: NNN.NNN.NNN.NNN
  Rural: P-NNNNNNNN.N/NNN
  """
  @spec format(String.t()) :: String.t()
  def format(<<"P", a::binary-size(8), b::binary-size(1), c::binary-size(3)>>) do
    "P-#{a}.#{b}/#{c}"
  end

  def format(<<a::binary-size(3), b::binary-size(3), c::binary-size(3), d::binary-size(3)>>) do
    "#{a}.#{b}.#{c}.#{d}"
  end

  def format(digits), do: digits
end
