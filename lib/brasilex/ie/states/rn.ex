defmodule Brasilex.IE.States.RN do
  @moduledoc false
  # Validates Rio Grande do Norte (RN) State Registration.
  #
  # Format: 9 or 10 digits
  # Prefix: "20" (first 2 digits always)
  # Check digit: last digit (Mod11 with weights 9-2 or 10-2, then multiply by 10)
  #
  # Example 9 digits: 20.040.040-1
  # Calculation:
  #   (2*9) + (0*8) + (0*7) + (4*6) + (0*5) + (0*4) + (4*3) + (0*2) = 54
  #   54 * 10 = 540
  #   540 mod 11 = 1 (check digit)
  #   If result is 10, digit is 0
  #
  # Example 10 digits: 20.0.040.040-0
  # Calculation:
  #   (2*10) + (0*9) + (0*8) + (0*7) + (4*6) + (0*5) + (0*4) + (4*3) + (0*2) = 56
  #   56 * 10 = 560
  #   560 mod 11 = 10 -> digit is 0

  alias Brasilex.IE.Checksum

  @weights_9 [9, 8, 7, 6, 5, 4, 3, 2]
  @weights_10 [10, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Rio Grande do Norte IE number (9 or 10 digits, prefix "20").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"20", _::binary-size(7)>> = digits), do: check(digits, @weights_9)
  def validate(<<"20", _::binary-size(8)>> = digits), do: check(digits, @weights_10)
  def validate(digits) when byte_size(digits) in [9, 10], do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  defp check(digits, weights) do
    {payload, dv} = String.split_at(digits, -1)

    if String.to_integer(dv) ==
         Checksum.mod11_dv(payload, weights, :rem_times_10_zero_when_10),
       do: :ok,
       else: {:error, :invalid_checksum}
  end

  @doc """
  Formats an IE number in RN format: NN.NNN.NNN-N or NN.N.NNN.NNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(1)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end

  def format(
        <<a::binary-size(2), b::binary-size(1), c::binary-size(3), d::binary-size(3),
          e::binary-size(1)>>
      ) do
    "#{a}.#{b}.#{c}.#{d}-#{e}"
  end
end
