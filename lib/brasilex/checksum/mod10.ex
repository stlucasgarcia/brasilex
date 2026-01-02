defmodule Brasilex.Checksum.Mod10 do
  @moduledoc """
  Implements the Modulo 10 check digit algorithm as defined by FEBRABAN.

  Used to validate individual fields in the linha digitável (typeable line)
  of Brazilian boletos.

  ## Algorithm

  1. Starting from right to left, multiply each digit alternately by 2 and 1
  2. If a product >= 10, sum its individual digits (e.g., 12 -> 1 + 2 = 3)
  3. Sum all resulting digits
  4. The check digit is `(10 - (sum mod 10)) mod 10`
  """

  @doc """
  Calculates the Modulo 10 check digit for a string of digits.

  ## Examples

      iex> Brasilex.Checksum.Mod10.calculate("341911012")
      1

      iex> Brasilex.Checksum.Mod10.calculate("3456788005")
      8

      iex> Brasilex.Checksum.Mod10.calculate("0000000000")
      0

  """
  @spec calculate(String.t()) :: non_neg_integer()
  def calculate(digits) when is_binary(digits) do
    digits
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {digit, index} ->
      multiplier = if rem(index, 2) == 0, do: 2, else: 1
      product = digit * multiplier
      sum_digits(product)
    end)
    |> Enum.sum()
    |> then(fn sum -> rem(10 - rem(sum, 10), 10) end)
  end

  @doc """
  Validates that a string ends with the correct Mod10 check digit.

  The last digit of the string is treated as the check digit, and
  is validated against the calculated check digit of the preceding digits.

  ## Examples

      iex> Brasilex.Checksum.Mod10.valid?("3419110121")
      true

      iex> Brasilex.Checksum.Mod10.valid?("3419110129")
      false

      iex> Brasilex.Checksum.Mod10.valid?("5")
      false

  """
  @spec valid?(String.t()) :: boolean()
  def valid?(digits) when is_binary(digits) and byte_size(digits) > 1 do
    {payload, <<check_digit::binary-size(1)>>} = String.split_at(digits, -1)
    calculate(payload) == String.to_integer(check_digit)
  end

  def valid?(_), do: false

  # Sums the digits of a number (e.g., 12 -> 1 + 2 = 3)
  defp sum_digits(n) when n < 10, do: n
  defp sum_digits(n), do: div(n, 10) + rem(n, 10)
end
