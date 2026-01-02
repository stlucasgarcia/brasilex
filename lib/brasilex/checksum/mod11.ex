defmodule Brasilex.Checksum.Mod11 do
  @moduledoc """
  Implements the Modulo 11 check digit algorithm as defined by FEBRABAN.

  Used to validate the general barcode check digit in Brazilian boletos.

  ## Algorithm

  1. Starting from right to left, multiply each digit by weights 2-9 cyclically
  2. Sum all products
  3. Calculate: `11 - (sum mod 11)`
  4. Special cases depend on boleto type:
     - Banking: 0, 1, 10, 11 → 1
     - Convenio: 0, 10, 11 → 0
  """

  @doc """
  Calculates the Modulo 11 check digit for banking boletos.

  Maps special cases 0, 1, 10, 11 → 1.

  ## Examples

      # All zeros yields sum=0, so 11-(0 mod 11)=11 -> special case returns 1
      iex> Brasilex.Checksum.Mod11.calculate("0000000000000000000000000000000000000000000")
      1

  """
  @spec calculate(String.t()) :: non_neg_integer()
  def calculate(digits) when is_binary(digits) do
    raw_calculate(digits, :banking)
  end

  @doc """
  Calculates the Modulo 11 check digit for convenio boletos.

  Maps special cases 0, 10, 11 → 0 (different from banking).
  """
  @spec calculate_convenio(String.t()) :: non_neg_integer()
  def calculate_convenio(digits) when is_binary(digits) do
    raw_calculate(digits, :convenio)
  end

  defp raw_calculate(digits, variant) do
    digits
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {digit, index} ->
      # Cycles through weights 2,3,4,5,6,7,8,9
      weight = rem(index, 8) + 2
      digit * weight
    end)
    |> Enum.sum()
    |> then(fn sum ->
      result = 11 - rem(sum, 11)
      map_special_cases(result, variant)
    end)
  end

  # Banking boletos: 0, 1, 10, 11 → 1
  defp map_special_cases(result, :banking) when result in [0, 1, 10, 11], do: 1
  defp map_special_cases(result, :banking), do: result

  # Convenio boletos: 0, 10, 11 → 0
  defp map_special_cases(result, :convenio) when result in [0, 10, 11], do: 0
  defp map_special_cases(result, :convenio), do: result

  @doc """
  Validates that a check digit matches the expected value for banking boletos.

  ## Examples

      iex> zeros = String.duplicate("0", 43)
      iex> Brasilex.Checksum.Mod11.valid?(zeros, 1)
      true

      iex> zeros = String.duplicate("0", 43)
      iex> Brasilex.Checksum.Mod11.valid?(zeros, "1")
      true

      iex> zeros = String.duplicate("0", 43)
      iex> Brasilex.Checksum.Mod11.valid?(zeros, 9)
      false

  """
  @spec valid?(String.t(), non_neg_integer() | String.t()) :: boolean()
  def valid?(digits, expected_check) when is_binary(expected_check) do
    valid?(digits, String.to_integer(expected_check))
  end

  def valid?(digits, expected_check) when is_integer(expected_check) do
    calculate(digits) == expected_check
  end

  @doc """
  Validates that a check digit matches the expected value for convenio boletos.

  Uses convenio variant of Mod11 (maps 0, 10, 11 → 0).
  """
  @spec valid_convenio?(String.t(), non_neg_integer() | String.t()) :: boolean()
  def valid_convenio?(digits, expected_check) when is_binary(expected_check) do
    valid_convenio?(digits, String.to_integer(expected_check))
  end

  def valid_convenio?(digits, expected_check) when is_integer(expected_check) do
    calculate_convenio(digits) == expected_check
  end
end
