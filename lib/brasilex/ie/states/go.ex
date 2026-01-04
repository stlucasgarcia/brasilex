defmodule Brasilex.IE.States.GO do
  @moduledoc false
  # Validates Goiás (GO) State Registration.
  #
  # Format: 9 digits
  # Prefix: 10, 11, or 20-29
  # Check digit: position 9 (Mod11 with weights 9,8,7,6,5,4,3,2)
  #
  # Example: 10.987.654-7
  # Calculation:
  #   (1*9) + (0*8) + (9*7) + (8*6) + (7*5) + (6*4) + (5*3) + (4*2) = 202
  #   202 mod 11 = 4
  #   11 - 4 = 7 (check digit)
  #
  # Special case: For IEs between 10103105 and 10119997, when remainder
  # is 0 or 1, check digit can be 0 or 1.

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Goiás IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 9 do
    with :ok <- validate_prefix(digits) do
      validate_checksum(digits)
    end
  end

  def validate(_), do: {:error, :invalid_length}

  defp validate_prefix(<<"10", _rest::binary>>), do: :ok
  defp validate_prefix(<<"11", _rest::binary>>), do: :ok
  defp validate_prefix(<<"2", d, _rest::binary>>) when d in ?0..?9, do: :ok
  defp validate_prefix(_), do: {:error, :invalid_prefix}

  defp validate_checksum(<<payload::binary-size(8), dv::binary-size(1)>> = digits) do
    calculated = calculate_dv(payload)
    actual = String.to_integer(dv)

    # Check for special case range
    if special_case?(digits, calculated) do
      if actual in [0, 1], do: :ok, else: {:error, :invalid_checksum}
    else
      if actual == calculated, do: :ok, else: {:error, :invalid_checksum}
    end
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

  # Special case: IEs between 10103105 and 10119997
  # When remainder is 0 or 1, DV can be 0 or 1
  defp special_case?(<<payload::binary-size(8), _dv::binary>>, calculated)
       when calculated in [0, 1] do
    value = String.to_integer(payload)
    value >= 10_103_105 and value <= 10_119_997
  end

  defp special_case?(_, _), do: false

  @doc """
  Formats an IE number in GO format: NN.NNN.NNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(1)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end

  def format(digits), do: digits
end
