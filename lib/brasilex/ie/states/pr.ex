defmodule Brasilex.IE.States.PR do
  @moduledoc false
  # Validates Paraná (PR) State Registration.
  #
  # Format: 10 digits (8 base + 2 check digits)
  # Mask: NNN.NNNNN-DD
  #
  # Algorithm: Mod11 with specific weight sequences
  # D1: weights 3,2,7,6,5,4,3,2 on first 8 digits
  # D2: weights 4,3,2,7,6,5,4,3,2 on first 9 digits (including D1)
  #
  # If result is 10 or 11, digit is 0
  #
  # Example: 123.45678-50

  alias Brasilex.IE.Checksum

  @weights_d1 [3, 2, 7, 6, 5, 4, 3, 2]
  @weights_d2 [4, 3, 2, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Paraná IE number (10 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(8), d1::binary-size(1), d2::binary-size(1)>>) do
    cond do
      String.to_integer(d1) != Checksum.mod11_dv(payload, @weights_d1) ->
        {:error, :invalid_checksum}

      String.to_integer(d2) != Checksum.mod11_dv(payload <> d1, @weights_d2) ->
        {:error, :invalid_checksum}

      true ->
        :ok
    end
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in PR format: NNN.NNNNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(3), b::binary-size(5), dv::binary-size(2)>>) do
    "#{a}.#{b}-#{dv}"
  end
end
