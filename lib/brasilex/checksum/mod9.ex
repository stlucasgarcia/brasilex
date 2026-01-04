defmodule Brasilex.Checksum.Mod9 do
  @moduledoc """
  Implements the Modulo 9 check digit algorithm used by Roraima (RR).

  ## Algorithm

  1. Multiply each digit by its position (1-indexed from left)
  2. Sum all products
  3. The check digit is the remainder when divided by 9

  ## Example

  For IE 24006153 (without check digit):
  - (2*1) + (4*2) + (0*3) + (0*4) + (6*5) + (1*6) + (5*7) + (3*8) = 105
  - 105 mod 9 = 6
  - Check digit = 6
  """

  @doc """
  Calculates the Modulo 9 check digit.

  Uses weights 1,2,3,4,5,6,7,8 from left to right.

  ## Examples

      iex> Brasilex.Checksum.Mod9.calculate("24006153")
      6

      iex> Brasilex.Checksum.Mod9.calculate("24001755")
      6

  """
  @spec calculate(String.t()) :: non_neg_integer()
  def calculate(digits) when is_binary(digits) do
    digits
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {digit, weight} -> digit * weight end)
    |> Enum.sum()
    |> rem(9)
  end

  @doc """
  Validates that a string ends with the correct Mod9 check digit.

  ## Examples

      iex> Brasilex.Checksum.Mod9.valid?("240061536")
      true

      iex> Brasilex.Checksum.Mod9.valid?("240061537")
      false

  """
  @spec valid?(String.t()) :: boolean()
  def valid?(digits) when is_binary(digits) and byte_size(digits) > 1 do
    {payload, <<check_char::binary-size(1)>>} = String.split_at(digits, -1)
    calculate(payload) == String.to_integer(check_char)
  end

  def valid?(_), do: false
end
