defmodule Brasilex.IE.States.DF do
  @moduledoc false
  # Validates Distrito Federal (DF) State Registration.
  #
  # Format: 13 digits (11 base + 2 check digits)
  # Structure: 07 + 6 sequential + 3 branch (001=matriz) + DD
  # Mask: 07.NNNNNN.NNN-DD
  #
  # Algorithm: Mod11 with weights 2-9 sequence (right to left)
  # D1: weights 4,3,2,9,8,7,6,5,4,3,2 on first 11 digits
  # D2: weights 5,4,3,2,9,8,7,6,5,4,3,2 on first 12 digits (including D1)
  # If result is 10 or 11, digit is 0
  #
  # Example: 07.300001.001-09

  alias Brasilex.IE.Checksum

  @weights_d1 [4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  @weights_d2 [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Distrito Federal IE number (13 digits, prefix "07").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"07", _::binary-size(11)>> = digits) do
    <<payload::binary-size(11), d1::binary-size(1), d2::binary-size(1)>> = digits

    cond do
      String.to_integer(d1) != Checksum.mod11_dv(payload, @weights_d1) ->
        {:error, :invalid_checksum}

      String.to_integer(d2) != Checksum.mod11_dv(payload <> d1, @weights_d2) ->
        {:error, :invalid_checksum}

      true ->
        :ok
    end
  end

  def validate(digits) when byte_size(digits) == 13, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in DF format: NN.NNNNNN.NNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), b::binary-size(6), c::binary-size(3), d::binary-size(2)>>) do
    "#{a}.#{b}.#{c}-#{d}"
  end
end
