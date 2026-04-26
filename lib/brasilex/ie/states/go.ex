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
  # Special case: For IEs between 10103105 and 10119997, when the
  # calculated digit would be 0 (remainder 0 or 1), the actual digit
  # may be either 0 or 1.

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Goiás IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(8), dv::binary-size(1)>> = digits) do
    with :ok <- validate_prefix(digits) do
      validate_checksum(payload, dv)
    end
  end

  def validate(_), do: {:error, :invalid_length}

  defp validate_prefix(<<"10", _::binary>>), do: :ok
  defp validate_prefix(<<"11", _::binary>>), do: :ok
  defp validate_prefix(<<"2", d, _::binary>>) when d in ?0..?9, do: :ok
  defp validate_prefix(_), do: {:error, :invalid_prefix}

  defp validate_checksum(payload, dv) do
    calculated = Checksum.mod11_dv(payload, @weights)
    actual = String.to_integer(dv)

    cond do
      actual == calculated -> :ok
      calculated == 0 and actual in [0, 1] and special_range?(payload) -> :ok
      true -> {:error, :invalid_checksum}
    end
  end

  # Special case range: 10103105..10119997
  defp special_range?(payload) do
    value = String.to_integer(payload)
    value >= 10_103_105 and value <= 10_119_997
  end

  @doc """
  Formats an IE number in GO format: NN.NNN.NNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(1)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end
end
