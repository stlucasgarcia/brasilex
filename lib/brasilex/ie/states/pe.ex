defmodule Brasilex.IE.States.PE do
  @moduledoc false
  # Validates Pernambuco (PE) State Registration.
  #
  # Two formats supported:
  #
  # 1. eFisco format (current): 9 digits (7 base + 2 check digits)
  #    - D1: weights 8,7,6,5,4,3,2 on first 7 digits
  #    - D2: weights 9,8,7,6,5,4,3,2 on first 8 digits (including D1)
  #    - If remainder is 0 or 1, digit is 0; else 11 - remainder
  #    - Example: 0321418-40
  #
  # 2. CACEPE format (legacy): 14 digits (13 base + 1 check digit)
  #    - Weights: 5,4,3,2,1,9,8,7,6,5,4,3,2
  #    - If result > 9, subtract 10
  #    - Example: 18.1.001.0000004-9

  alias Brasilex.IE.Checksum

  @weights_d1 [8, 7, 6, 5, 4, 3, 2]
  @weights_d2 [9, 8, 7, 6, 5, 4, 3, 2]
  @weights_legacy [5, 4, 3, 2, 1, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Pernambuco IE number (9 or 14 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(7), d1::binary-size(1), d2::binary-size(1)>>) do
    cond do
      String.to_integer(d1) != Checksum.mod11_dv(payload, @weights_d1) ->
        {:error, :invalid_checksum}

      String.to_integer(d2) != Checksum.mod11_dv(payload <> d1, @weights_d2) ->
        {:error, :invalid_checksum}

      true ->
        :ok
    end
  end

  def validate(<<payload::binary-size(13), dv::binary-size(1)>>) do
    if String.to_integer(dv) ==
         Checksum.mod11_dv(payload, @weights_legacy, :subtract_10_when_gt_9),
       do: :ok,
       else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in PE format.
  eFisco (9 digits): NNNNNNN-NN
  Legacy (14 digits): NN.N.NNN.NNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(7), dv::binary-size(2)>>) do
    "#{payload}-#{dv}"
  end

  def format(
        <<a::binary-size(2), b::binary-size(1), c::binary-size(3), d::binary-size(7),
          e::binary-size(1)>>
      ) do
    "#{a}.#{b}.#{c}.#{d}-#{e}"
  end
end
