defmodule Brasilex.IE.States.AC do
  @moduledoc false
  # Validates Acre (AC) State Registration.
  #
  # Format: 13 digits (11 + 2 check digits)
  # Prefix: "01" (first 2 digits always)
  #
  # D1 calculation: Mod11 with weights 4,3,2,9,8,7,6,5,4,3,2
  # D2 calculation: Mod11 with weights 5,4,3,2,9,8,7,6,5,4,3,2 (includes D1)
  #
  # Example: 01.004.823/001-12

  alias Brasilex.IE.Checksum

  @weights_d1 [4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  @weights_d2 [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates an Acre IE number (13 digits, prefix "01").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"01", _::binary-size(11)>> = digits) do
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
  Formats an IE number in AC format: NN.NNN.NNN/NNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(
        <<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(3),
          e::binary-size(2)>>
      ) do
    "#{a}.#{b}.#{c}/#{d}-#{e}"
  end
end
