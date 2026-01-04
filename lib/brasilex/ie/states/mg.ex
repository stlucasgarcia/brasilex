defmodule Brasilex.IE.States.MG do
  @moduledoc false
  # Validates Minas Gerais (MG) State Registration.
  #
  # Format: 13 digits
  # Structure: CCCNNNNNNNNNDD where:
  #   - CCC = municipality code (3 digits)
  #   - NNNNNNNNN = sequential number (8 digits + 2 order digits = 10 digits)
  #   - D1 = first check digit (position 12)
  #   - D2 = second check digit (position 13)
  #
  # D1 calculation (unique to MG):
  #   1. Insert "0" after position 3: CCC0NNNNNNNN (12 digits)
  #   2. Alternate weights 1,2,1,2... from left
  #   3. For products >= 10, sum digits (e.g., 12 -> 1+2 = 3)
  #   4. Sum all results
  #   5. Round up to nearest 10, subtract sum
  #   6. Result mod 10 = D1
  #
  # D2 calculation (Mod11):
  #   Weights: 3,2,11,10,9,8,7,6,5,4,3,2 on first 12 digits (including D1)
  #   If remainder < 2, D2 = 0
  #   Otherwise D2 = 11 - remainder
  #
  # Example: 062.307.904/0081
  # D1: Insert 0 after 062 -> 0620307904 00
  #     (0*1)+(6*2)+(2*1)+(0*2)+(3*1)+(0*2)+(7*1)+(9*2)+(0*1)+(4*2)+(0*1)+(0*2)
  #     = 0+12+2+0+3+0+7+18+0+8+0+0 -> 0+(1+2)+2+0+3+0+7+(1+8)+0+8+0+0 = 32
  #     Next 10 = 40, 40 - 32 = 8 -> D1 = 8
  #
  # D2: 0623079040081 (12 digits)
  #     Weights: 3,2,11,10,9,8,7,6,5,4,3,2
  #     Sum = 219, 219 mod 11 = 10, 11 - 10 = 1 -> D2 = 1

  @weights_d2 [3, 2, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Minas Gerais IE number (13 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 13 do
    with :ok <- validate_d1(digits) do
      validate_d2(digits)
    end
  end

  def validate(_), do: {:error, :invalid_length}

  # Validate first check digit (position 12)
  defp validate_d1(<<
         p1::binary-size(3),
         p2::binary-size(8),
         d1::binary-size(1),
         _d2::binary-size(1)
       >>) do
    # Insert "0" after municipality code
    payload = p1 <> "0" <> p2

    calculated = calculate_d1(payload)

    if String.to_integer(d1) == calculated do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  # Validate second check digit (position 13)
  defp validate_d2(<<payload::binary-size(12), d2::binary-size(1)>>) do
    calculated = calculate_d2(payload)

    if String.to_integer(d2) == calculated do
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
      |> Enum.with_index()
      |> Enum.map(fn {digit, index} ->
        weight = if rem(index, 2) == 0, do: 1, else: 2
        product = digit * weight
        sum_digits(product)
      end)
      |> Enum.sum()

    # Round up to nearest 10, then subtract
    next_ten = ceil(sum / 10) * 10
    rem(next_ten - sum, 10)
  end

  defp sum_digits(n) when n < 10, do: n
  defp sum_digits(n), do: div(n, 10) + rem(n, 10)

  defp calculate_d2(payload) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(@weights_d2)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    remainder = rem(sum, 11)

    if remainder < 2 do
      0
    else
      11 - remainder
    end
  end

  @doc """
  Formats an IE number in MG format: NNN.NNN.NNN/NNNN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(3), b::binary-size(3), c::binary-size(3), d::binary-size(4)>>) do
    "#{a}.#{b}.#{c}/#{d}"
  end

  def format(digits), do: digits
end
