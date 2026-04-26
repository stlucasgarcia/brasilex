defmodule Brasilex.IE.States.AP do
  @moduledoc false
  # Validates Amapá (AP) State Registration.
  #
  # Format: 9 digits (03 + 6 digits + 1 check digit)
  # Prefix: "03" (always)
  #
  # Special values p and d based on IE range:
  #   03000001 to 03017000 => p = 5, d = 0
  #   03017001 to 03019022 => p = 9, d = 1
  #   03019023 onwards     => p = 0, d = 0
  #
  # Algorithm: p + sum(weights 9-2) mod 11
  # If result is 10, digit is 0
  # If result is 11, digit is d
  #
  # Example: 030123459

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates an Amapá IE number (9 digits, prefix "03").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"03", _::binary-size(7)>> = digits) do
    <<payload::binary-size(8), dv::binary-size(1)>> = digits

    if String.to_integer(dv) == calculate_dv(payload),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(digits) when byte_size(digits) == 9, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  defp calculate_dv(payload) do
    {p, d} = get_p_and_d(payload)
    sum = Checksum.weighted_sum(payload, @weights)
    result = 11 - rem(p + sum, 11)

    cond do
      result == 10 -> 0
      result == 11 -> d
      true -> result
    end
  end

  defp get_p_and_d(payload) do
    value = String.to_integer(payload)

    cond do
      value >= 3_000_001 and value <= 3_017_000 -> {5, 0}
      value >= 3_017_001 and value <= 3_019_022 -> {9, 1}
      true -> {0, 0}
    end
  end

  @doc """
  Formats an IE number in AP format: NNNNNNNNN
  """
  @spec format(String.t()) :: String.t()
  def format(digits) when byte_size(digits) == 9, do: digits
end
