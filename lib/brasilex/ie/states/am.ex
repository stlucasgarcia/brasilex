defmodule Brasilex.IE.States.AM do
  @moduledoc false
  # Validates Amazonas (AM) State Registration.
  #
  # Format: 9 digits
  # Mask: NN.NNN.NNN-N
  #
  # Algorithm: Mod11 with weights 9,8,7,6,5,4,3,2
  # Special case: if sum < 11, digit = 11 - sum
  # Otherwise: if remainder <= 1, digit = 0, else digit = 11 - remainder
  #
  # Example: 04.123.456-7

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates an Amazonas IE number (9 digits).
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

    if sum < 11 do
      11 - sum
    else
      remainder = rem(sum, 11)
      if remainder <= 1, do: 0, else: 11 - remainder
    end
  end

  @doc """
  Formats an IE number in AM format: NN.NNN.NNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(1)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end

  def format(digits), do: digits
end
