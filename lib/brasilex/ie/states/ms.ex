defmodule Brasilex.IE.States.MS do
  @moduledoc false
  # Validates Mato Grosso do Sul (MS) State Registration.
  #
  # Format: 9 digits
  # Prefix: "28"
  # Check digit: position 9 (Mod11 with weights 9,8,7,6,5,4,3,2)
  #
  # Formula:
  #   A = (1st*9) + (2nd*8) + (3rd*7) + (4th*6) + (5th*5) + (6th*4) + (7th*3) + (8th*2)
  #   R = A mod 11
  #   If R = 0, D = 0
  #   If R > 0, T = 11 - R
  #     If T > 9, D = 0
  #     If T < 10, D = T

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Mato Grosso do Sul IE number (9 digits, prefix "28").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"28", _rest::binary>> = digits) when byte_size(digits) == 9 do
    if valid_checksum?(digits) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  def validate(digits) when byte_size(digits) == 9, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  defp valid_checksum?(<<payload::binary-size(8), dv::binary-size(1)>>) do
    calculated = calculate_dv(payload)
    String.to_integer(dv) == calculated
  end

  defp calculate_dv(payload) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(@weights)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    remainder = rem(sum, 11)

    cond do
      remainder == 0 -> 0
      (11 - remainder) > 9 -> 0
      true -> 11 - remainder
    end
  end

  @doc """
  Formats an IE number in MS format: NN.NNN.NNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(1)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end

  def format(digits), do: digits
end
