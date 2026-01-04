defmodule Brasilex.IE.States.MA do
  @moduledoc false
  # Validates Maranhão (MA) State Registration.
  #
  # Format: 9 digits (8 base + 1 check digit)
  # Prefix: "12" (state code)
  #
  # Algorithm: Mod11 with weights 9-2
  # If remainder is 0 or 1, digit is 0
  # Otherwise digit is 11 - remainder
  #
  # Example: 12000038-5

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Maranhão IE number (9 digits, prefix "12").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"12", _rest::binary>> = digits) when byte_size(digits) == 9 do
    if valid_checksum?(digits), do: :ok, else: {:error, :invalid_checksum}
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

    if remainder in [0, 1], do: 0, else: 11 - remainder
  end

  @doc """
  Formats an IE number in MA format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end

  def format(digits), do: digits
end
