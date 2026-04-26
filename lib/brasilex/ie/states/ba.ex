defmodule Brasilex.IE.States.BA do
  @moduledoc false
  # Validates Bahia (BA) State Registration.
  #
  # Format: 8 or 9 digits (NNNNNN-DD or NNNNNNN-DD)
  #
  # Algorithm depends on first digit (8 digits) or second digit (9 digits):
  #   - 0,1,2,3,4,5,8 => Mod10
  #   - 6,7,9 => Mod11
  #
  # For 8 digits:
  #   D2 calculated first with weights 7-2 (or 8-2 for mod11)
  #   D1 calculated with weights 8-2 including D2 (or 9-2 for mod11)
  #
  # For 9 digits:
  #   D2 calculated first with weights 8-2 (or 9-2 for mod11)
  #   D1 calculated with weights 9-2 including D2 (or 10-2 for mod11)
  #
  # Examples: 123456-63 (8 digits, mod10), 612345-57 (8 digits, mod11)
  #           1000003-06 (9 digits, mod10)

  alias Brasilex.IE.Checksum

  @doc """
  Validates a Bahia IE number (8 or 9 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<first::binary-size(1), _::binary-size(7)>> = digits) do
    validate_with(digits, get_modulo(first), 8)
  end

  def validate(<<_::binary-size(1), second::binary-size(1), _::binary-size(7)>> = digits) do
    validate_with(digits, get_modulo(second), 9)
  end

  def validate(_), do: {:error, :invalid_length}

  defp get_modulo(digit) when digit in ~w(0 1 2 3 4 5 8), do: 10
  defp get_modulo(digit) when digit in ~w(6 7 9), do: 11

  defp validate_with(digits, modulo, length) do
    payload_size = length - 2

    <<payload_d2::binary-size(payload_size), d1_str::binary-size(1), d2_str::binary-size(1)>> =
      digits

    {weights_d2, weights_d1} = weights_for(length)
    calculated_d2 = calc_dv(payload_d2, weights_d2, modulo)

    cond do
      String.to_integer(d2_str) != calculated_d2 ->
        {:error, :invalid_checksum}

      String.to_integer(d1_str) != calc_dv(payload_d2 <> d2_str, weights_d1, modulo) ->
        {:error, :invalid_checksum}

      true ->
        :ok
    end
  end

  defp weights_for(8), do: {[7, 6, 5, 4, 3, 2], [8, 7, 6, 5, 4, 3, 2]}
  defp weights_for(9), do: {[8, 7, 6, 5, 4, 3, 2], [9, 8, 7, 6, 5, 4, 3, 2]}

  # Mod10 here is "if remainder == 0, 0; else 10 - remainder" — different from
  # FEBRABAN Mod10 (which doubles digits and reduces). Inline by design.
  defp calc_dv(payload, weights, 10) do
    case rem(Checksum.weighted_sum(payload, weights), 10) do
      0 -> 0
      r -> 10 - r
    end
  end

  defp calc_dv(payload, weights, 11), do: Checksum.mod11_dv(payload, weights)

  @doc """
  Formats an IE number in BA format: NNNNNN-NN or NNNNNNN-NN
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(6), dv::binary-size(2)>>), do: "#{payload}-#{dv}"
  def format(<<payload::binary-size(7), dv::binary-size(2)>>), do: "#{payload}-#{dv}"
end
