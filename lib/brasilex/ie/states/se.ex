defmodule Brasilex.IE.States.SE do
  @moduledoc false
  # Validates Sergipe (SE) State Registration.
  #
  # Format: 9 digits
  # Check digit: position 9 (Mod11 with weights 9,8,7,6,5,4,3,2)
  #
  # Example: 27123456-3
  # Calculation:
  #   (2*9) + (7*8) + (1*7) + (2*6) + (3*5) + (4*4) + (5*3) + (6*2) = 151
  #   151 mod 11 = 8
  #   11 - 8 = 3 (check digit)

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Sergipe IE number (9 digits).
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

    # When remainder is 10 or 11, digit is 0
    if remainder in [0, 1], do: 0, else: 11 - remainder
  end

  @doc """
  Formats an IE number in SE format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end

  def format(digits), do: digits
end
