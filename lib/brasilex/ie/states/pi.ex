defmodule Brasilex.IE.States.PI do
  @moduledoc false
  # Validates Piauí (PI) State Registration.
  #
  # Format: 9 digits (8 base + 1 check digit)
  #
  # Algorithm: Mod11 with weights 9-2
  # If result is 10 or 11, digit is 0
  # Otherwise digit is 11 - remainder
  #
  # Example: 01234567-9

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Piauí IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 9 do
    if valid_checksum?(digits), do: :ok, else: {:error, :invalid_checksum}
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
    result = 11 - remainder

    if result in [10, 11], do: 0, else: result
  end

  @doc """
  Formats an IE number in PI format: NNNNNNNNN
  """
  @spec format(String.t()) :: String.t()
  def format(digits), do: digits
end
