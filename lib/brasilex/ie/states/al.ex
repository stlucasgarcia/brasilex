defmodule Brasilex.IE.States.AL do
  @moduledoc false
  # Validates Alagoas (AL) State Registration.
  #
  # Format: 9 digits (24XNNNNND)
  # Structure:
  #   - 24 = State code (always)
  #   - X = Company type (0=Normal, 3=Rural, 5=Substitute, 7=Ambulant, 8=Micro)
  #   - NNNNN = Company number
  #   - D = Check digit
  #
  # Algorithm: Mod11 with weights 9-2, multiply sum by 10, remainder is check digit
  # If remainder is 10, digit is 0
  #
  # Example: 240000048

  @weights [9, 8, 7, 6, 5, 4, 3, 2]
  @valid_types ~w(0 3 5 7 8)

  @doc """
  Validates an Alagoas IE number (9 digits, prefix "24").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"24", type::binary-size(1), _rest::binary>> = digits) when byte_size(digits) == 9 do
    if type in @valid_types do
      if valid_checksum?(digits), do: :ok, else: {:error, :invalid_checksum}
    else
      {:error, :invalid_format}
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

    result = rem(sum * 10, 11)
    if result == 10, do: 0, else: result
  end

  @doc """
  Formats an IE number in AL format: NNNNNNNNN
  """
  @spec format(String.t()) :: String.t()
  def format(digits), do: digits
end
