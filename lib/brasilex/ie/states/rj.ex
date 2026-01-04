defmodule Brasilex.IE.States.RJ do
  @moduledoc false
  # Validates Rio de Janeiro (RJ) State Registration.
  #
  # Format: 8 digits (7 base + 1 check digit)
  # Mask: NN.NNN.NN-N
  #
  # Algorithm: Mod11 with weights 2,7,6,5,4,3,2
  # If remainder <= 1, digit is 0
  # Otherwise digit is 11 - remainder
  #
  # Example: 99.999.99-3

  @weights [2, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Rio de Janeiro IE number (8 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 8 do
    if valid_checksum?(digits), do: :ok, else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  defp valid_checksum?(<<payload::binary-size(7), dv::binary-size(1)>>) do
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

    if remainder <= 1, do: 0, else: 11 - remainder
  end

  @doc """
  Formats an IE number in RJ format: NN.NNN.NN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(2), d::binary-size(1)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end

  def format(digits), do: digits
end
