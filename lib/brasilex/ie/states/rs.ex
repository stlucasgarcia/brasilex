defmodule Brasilex.IE.States.RS do
  @moduledoc false
  # Validates Rio Grande do Sul (RS) State Registration.
  #
  # Format: 10 digits (3 municipality + 6 company + 1 check digit)
  # Check digit: position 10 (Mod11 with weights 2,9,8,7,6,5,4,3,2)
  #
  # Example: 224/3658792
  # Calculation:
  #   (2*2) + (2*9) + (4*8) + (3*7) + (6*6) + (5*5) + (8*4) + (7*3) + (9*2) = 207
  #   207 mod 11 = 9
  #   11 - 9 = 2 (check digit)

  alias Brasilex.IE.Checksum

  @weights [2, 9, 8, 7, 6, 5, 4, 3, 2]

  @doc """
  Validates a Rio Grande do Sul IE number (10 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(<<payload::binary-size(9), dv::binary-size(1)>>) do
    if String.to_integer(dv) == Checksum.mod11_dv(payload, @weights),
      do: :ok,
      else: {:error, :invalid_checksum}
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in RS format: NNN/NNNNNNN
  """
  @spec format(String.t()) :: String.t()
  def format(<<municipality::binary-size(3), rest::binary-size(7)>>) do
    "#{municipality}/#{rest}"
  end
end
