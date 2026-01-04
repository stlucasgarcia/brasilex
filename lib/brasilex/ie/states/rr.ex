defmodule Brasilex.IE.States.RR do
  @moduledoc false
  # Validates Roraima (RR) State Registration.
  #
  # Format: 9 digits
  # Prefix: "24" (first 2 digits always represent the state)
  # Check digit: position 9 (Mod9 with weights 1,2,3,4,5,6,7,8)
  #
  # Roraima is unique in using Mod9 instead of Mod11.
  #
  # Example: 24006153-6
  # Calculation:
  #   (2*1) + (4*2) + (0*3) + (0*4) + (6*5) + (1*6) + (5*7) + (3*8) = 105
  #   105 mod 9 = 6 (check digit)

  alias Brasilex.Checksum.Mod9

  @doc """
  Validates a Roraima IE number (9 digits, prefix "24").
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<"24", _rest::binary-size(7)>> = digits) when byte_size(digits) == 9 do
    if Mod9.valid?(digits) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  def validate(digits) when byte_size(digits) == 9, do: {:error, :invalid_prefix}
  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in RR format: NNNNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<payload::binary-size(8), dv::binary-size(1)>>) do
    "#{payload}-#{dv}"
  end

  def format(digits), do: digits
end
