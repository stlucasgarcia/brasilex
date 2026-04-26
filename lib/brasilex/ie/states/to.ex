defmodule Brasilex.IE.States.TO do
  @moduledoc false
  # Validates Tocantins (TO) State Registration.
  #
  # Format: 11 digits
  # Structure: AATTSSSSSSD where:
  #   - AA = first 2 digits (included in calculation)
  #   - TT = type code at positions 3-4 (NOT included in calculation)
  #   - SSSSSS = sequential digits (positions 5-10, included in calculation)
  #   - D = check digit (position 11)
  #
  # Valid type codes:
  #   01 = Produtor Rural
  #   02 = Indústria e Comércio
  #   03 = Empresas Rudimentares
  #   99 = Empresas do Cadastro Antigo (Suspensas)
  #
  # Mod11 with weights 9,8,7,6,5,4,3,2 applied to positions 1,2,5,6,7,8,9,10
  #
  # Example: 29 01 022783 6
  # Calculation (using positions 1,2,5,6,7,8,9,10):
  #   (2*9) + (9*8) + (0*7) + (2*6) + (2*5) + (7*4) + (8*3) + (3*2) = 170
  #   170 mod 11 = 5
  #   11 - 5 = 6 (check digit)
  #
  # If remainder < 2, digit = 0

  alias Brasilex.IE.Checksum

  @weights [9, 8, 7, 6, 5, 4, 3, 2]
  @valid_type_codes ["01", "02", "03", "99"]

  @doc """
  Validates a Tocantins IE number (11 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(
        <<p1::binary-size(2), type::binary-size(2), p2::binary-size(6), dv::binary-size(1)>>
      ) do
    cond do
      type not in @valid_type_codes ->
        {:error, :invalid_format}

      String.to_integer(dv) != Checksum.mod11_dv(p1 <> p2, @weights) ->
        {:error, :invalid_checksum}

      true ->
        :ok
    end
  end

  def validate(_), do: {:error, :invalid_length}

  @doc """
  Formats an IE number in TO format: NN.TT.NNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), type::binary-size(2), b::binary-size(6), d::binary-size(1)>>) do
    "#{a}.#{type}.#{b}-#{d}"
  end
end
