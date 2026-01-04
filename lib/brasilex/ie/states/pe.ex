defmodule Brasilex.IE.States.PE do
  @moduledoc false
  # Validates Pernambuco (PE) State Registration.
  #
  # Two formats supported:
  #
  # 1. eFisco format (current): 9 digits (7 base + 2 check digits)
  #    - D1: weights 8,7,6,5,4,3,2 on first 7 digits
  #    - D2: weights 9,8,7,6,5,4,3,2 on first 8 digits (including D1)
  #    - If remainder is 0 or 1, digit is 0; else 11 - remainder
  #    - Example: 0321418-40
  #
  # 2. CACEPE format (legacy): 14 digits (13 base + 1 check digit)
  #    - Weights: 5,4,3,2,1,9,8,7,6,5,4,3,2
  #    - If result > 9, subtract 10
  #    - Example: 18.1.001.0000004-9

  @weights_d1 [8, 7, 6, 5, 4, 3, 2]
  @weights_d2 [9, 8, 7, 6, 5, 4, 3, 2]
  @weights_legacy [5, 4, 3, 2, 1, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Pernambuco IE number (9 or 14 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 9 do
    if valid_checksum_efisco?(digits), do: :ok, else: {:error, :invalid_checksum}
  end

  def validate(digits) when byte_size(digits) == 14 do
    if valid_checksum_legacy?(digits), do: :ok, else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  # eFisco format: 7 base + 2 check digits
  defp valid_checksum_efisco?(<<payload::binary-size(7), d1::binary-size(1), d2::binary-size(1)>>) do
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

    if remainder in [0, 1], do: 0, else: 11 - remainder
  end

  # Legacy CACEPE format: 13 base + 1 check digit
  defp valid_checksum_legacy?(<<payload::binary-size(13), dv::binary-size(1)>>) do
    calculated = calculate_dv_legacy(payload)
    String.to_integer(dv) == calculated
  end

  defp calculate_dv_legacy(payload) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(@weights_legacy)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    remainder = rem(sum, 11)
    result = 11 - remainder

    if result > 9, do: result - 10, else: result
  end

  @doc """
  Formats an IE number in PE format.
  eFisco (9 digits): NNNNNNN-NN
  Legacy (14 digits): NN.N.NNN.NNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(7), dv::binary-size(2)>>) do
    "#{payload}-#{dv}"
  end

  def format(<<a::binary-size(2), b::binary-size(1), c::binary-size(3), d::binary-size(7), e::binary-size(1)>>) do
    "#{a}.#{b}.#{c}.#{d}-#{e}"
  end

  def format(digits), do: digits
end
