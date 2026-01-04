defmodule Brasilex.IE.States.BA do
  @moduledoc false
  # Validates Bahia (BA) State Registration.
  #
  # Format: 8 or 9 digits (NNNNNN-DD or NNNNNNN-DD)
  #
  # Algorithm depends on first digit (8 digits) or second digit (9 digits):
  #   - 0,1,2,3,4,5,8 => Mod10
  #   - 6,7,9 => Mod11
  #
  # For 8 digits:
  #   D2 calculated first with weights 7-2 (or 8-2 for mod11)
  #   D1 calculated with weights 8-2 including D2 (or 9-2 for mod11)
  #
  # For 9 digits:
  #   D2 calculated first with weights 8-2 (or 9-2 for mod11)
  #   D1 calculated with weights 9-2 including D2 (or 10-2 for mod11)
  #
  # Examples: 123456-63 (8 digits, mod10), 612345-57 (8 digits, mod11)
  #           1000003-06 (9 digits, mod10)

  @doc """
  Validates a Bahia IE number (8 or 9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 8 do
    validate_8_digits(digits)
  end

  def validate(digits) when byte_size(digits) == 9 do
    validate_9_digits(digits)
  end

  def validate(_), do: {:error, :invalid_length}

  # 8-digit validation
  defp validate_8_digits(<<first::binary-size(1), _rest::binary>> = digits) do
    modulo = get_modulo(first)
    validate_with_modulo(digits, modulo, 8)
  end

  # 9-digit validation
  defp validate_9_digits(<<_first::binary-size(1), second::binary-size(1), _rest::binary>> = digits) do
    modulo = get_modulo(second)
    validate_with_modulo(digits, modulo, 9)
  end

  defp get_modulo(digit) when digit in ~w(0 1 2 3 4 5 8), do: 10
  defp get_modulo(digit) when digit in ~w(6 7 9), do: 11

  defp validate_with_modulo(digits, modulo, length) do
    {payload_d2, d1_str, d2_str} = split_digits(digits, length)

    # Calculate D2 first
    calculated_d2 = calculate_d2(payload_d2, modulo, length)

    if String.to_integer(d2_str) != calculated_d2 do
      {:error, :invalid_checksum}
    else
      # Calculate D1 with D2 included
      payload_d1 = payload_d2 <> d2_str
      calculated_d1 = calculate_d1(payload_d1, modulo, length)

      if String.to_integer(d1_str) == calculated_d1, do: :ok, else: {:error, :invalid_checksum}
    end
  end

  defp split_digits(digits, 8) do
    <<payload::binary-size(6), d1::binary-size(1), d2::binary-size(1)>> = digits
    {payload, d1, d2}
  end

  defp split_digits(digits, 9) do
    <<payload::binary-size(7), d1::binary-size(1), d2::binary-size(1)>> = digits
    {payload, d1, d2}
  end

  # D2 calculation (6 or 7 digits)
  defp calculate_d2(payload, modulo, length) do
    weights = if length == 8, do: [7, 6, 5, 4, 3, 2], else: [8, 7, 6, 5, 4, 3, 2]
    calculate_digit(payload, weights, modulo)
  end

  # D1 calculation (7 or 8 digits, includes D2)
  defp calculate_d1(payload, modulo, length) do
    weights = if length == 8, do: [8, 7, 6, 5, 4, 3, 2], else: [9, 8, 7, 6, 5, 4, 3, 2]
    calculate_digit(payload, weights, modulo)
  end

  defp calculate_digit(payload, weights, modulo) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(weights)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    remainder = rem(sum, modulo)

    cond do
      remainder == 0 -> 0
      modulo == 11 and remainder == 1 -> 0
      true -> modulo - remainder
    end
  end

  @doc """
  Formats an IE number in BA format: NNNNNN-NN or NNNNNNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(6), dv::binary-size(2)>>) do
    "#{payload}-#{dv}"
  end

  def format(<<payload::binary-size(7), dv::binary-size(2)>>) do
    "#{payload}-#{dv}"
  end

  def format(digits), do: digits
end
