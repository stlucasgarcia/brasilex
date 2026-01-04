defmodule Brasilex.IE.States.AC do
  @moduledoc false
  # Validates Acre (AC) State Registration.
  #
  # Format: 13 digits (11 + 2 check digits)
  # Prefix: "01" (first 2 digits always)
  #
  # D1 calculation: Mod11 with weights 4,3,2,9,8,7,6,5,4,3,2
  # D2 calculation: Mod11 with weights 5,4,3,2,9,8,7,6,5,4,3,2 (includes D1)
  #
  # Example: 01.004.823/001-12

  @weights_d1 [4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  @weights_d2 [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates an Acre IE number (13 digits, prefix "01").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"01", _rest::binary>> = digits) when byte_size(digits) == 13 do
    with :ok <- validate_d1(digits) do
      validate_d2(digits)
    end
  end

  def validate(digits) when byte_size(digits) == 13, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  defp validate_d1(<<payload::binary-size(11), d1::binary-size(1), _d2::binary-size(1)>>) do
    calculated = calculate_dv(payload, @weights_d1)
    if String.to_integer(d1) == calculated, do: :ok, else: {:error, :invalid_checksum}
  end

  defp validate_d2(<<payload::binary-size(12), d2::binary-size(1)>>) do
    calculated = calculate_dv(payload, @weights_d2)
    if String.to_integer(d2) == calculated, do: :ok, else: {:error, :invalid_checksum}
  end

  defp calculate_dv(payload, weights) do
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
  Formats an IE number in AC format: NN.NNN.NNN/NNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(3), e::binary-size(2)>>) do
    "#{a}.#{b}.#{c}/#{d}-#{e}"
  end

  def format(digits), do: digits
end
