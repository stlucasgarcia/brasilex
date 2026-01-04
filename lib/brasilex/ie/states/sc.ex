defmodule Brasilex.IE.States.SC do
  @moduledoc false
  # Validates Santa Catarina (SC) State Registration.
  #
  # Format: 9 digits
  # Check digit: position 9 (Mod11 with weights 9,8,7,6,5,4,3,2)
  #
  # Example: 251.040.852
  # Calculation:
  #   (2*9) + (5*8) + (1*7) + (0*6) + (4*5) + (0*4) + (8*3) + (5*2) = 119
  #   119 mod 11 = 9
  #   11 - 9 = 2 (check digit)

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Santa Catarina IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 9 do
    if valid_checksum?(digits) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

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

    if remainder in [0, 1], do: 0, else: 11 - remainder
  end

  @doc """
  Formats an IE number in SC format: NNN.NNN.NNN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(3), b::binary-size(3), c::binary-size(3)>>) do
    "#{a}.#{b}.#{c}"
  end

  def format(digits), do: digits
end
