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

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates an Amazonas IE number (9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(8), dv::binary-size(1)>>) do
    if String.to_integer(dv) == calculate_dv(payload),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  defp calculate_dv(payload) do
    sum = Checksum.weighted_sum(payload, @weights)

    cond do
      sum < 11 -> 11 - sum
      rem(sum, 11) in [0, 1] -> 0
      true -> 11 - rem(sum, 11)
    end
  end

  @doc """
  Formats an IE number in AM format: NN.NNN.NNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(1)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end
end
