defmodule Brasilex.IE.States.MT do
  @moduledoc false
  # Validates Mato Grosso (MT) State Registration.
  #
  # Format: 11 digits (10 digits + 1 check digit)
  # Weights: 3,2,9,8,7,6,5,4,3,2 (Mod11 cycling 2-9, then 2-3)
  #
  # Example: 0013000001-9
  # Calculation:
  #   (0*3)+(0*2)+(1*9)+(3*8)+(0*7)+(0*6)+(0*5)+(0*4)+(0*3)+(1*2) = 35
  #   35 mod 11 = 2
  #   11 - 2 = 9 (check digit)
  #
  # If remainder is 0 or 1, digit = 0

  @weights [3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Mato Grosso IE number (11 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 11 do
    if valid_checksum?(digits) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  def validate(_), do: {:error, :invalid_length}

  defp valid_checksum?(<<payload::binary-size(10), dv::binary-size(1)>>) do
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
  Formats an IE number in MT format: NNNNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(10), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end

  def format(digits), do: digits
end
