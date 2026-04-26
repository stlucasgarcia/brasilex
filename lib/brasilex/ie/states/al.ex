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

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]
  @valid_types ~w(0 3 5 7 8)

  @doc """
  Validates an Alagoas IE number (9 digits, prefix "24").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"24", type::binary-size(1), _::binary-size(6)>> = digits) do
    cond do
      type not in @valid_types ->
        {:error, :invalid_format}

      not valid_checksum?(digits) ->
        {:error, :invalid_checksum}

      true ->
        :ok
    end
  end

  def validate(digits) when byte_size(digits) == 9, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  defp valid_checksum?(<<payload::binary-size(8), dv::binary-size(1)>>) do
    String.to_integer(dv) == Checksum.mod11_dv(payload, @weights, :rem_times_10_zero_when_10)
  end

  @doc """
  Formats an IE number in AL format: NNNNNNNNN
  """
  @spec format(String.t()) :: String.t()
  def format(digits) when byte_size(digits) == 9, do: digits
end
