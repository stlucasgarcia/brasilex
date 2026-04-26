defmodule Brasilex.IE.States.PA do
  @moduledoc false
  # Validates Pará (PA) State Registration.
  #
  # Format: 9 digits (8 base + 1 check digit)
  # Prefix: "15", "75", "76", "77", "78", or "79"
  #
  # Algorithm: Mod11 with weights 9-2
  # If remainder is 0 or 1, digit is 0
  # Otherwise digit is 11 - remainder
  #
  # Examples: 15999999-5, 75000002-3

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]
  @valid_prefixes ["15", "75", "76", "77", "78", "79"]

  @doc """
  Validates a Pará IE number (9 digits, valid prefix).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<prefix::binary-size(2), _rest::binary>> = digits) when byte_size(digits) == 9 do
    if prefix in @valid_prefixes do
      <<payload::binary-size(8), dv::binary-size(1)>> = digits

      if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
        do: :ok,
        else: {:error, :invalid_checksum}
    else
      {:error, :invalid_prefix}
    end
  end

  def validate(digits) when byte_size(digits) == 9, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in PA format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end
end
