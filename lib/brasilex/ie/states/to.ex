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

  @weights [9, 8, 7, 6, 5, 4, 3, 2]
  @valid_type_codes ["01", "02", "03", "99"]

  @doc """
  Validates a Tocantins IE number (11 digits).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(digits) when byte_size(digits) == 11 do
    with :ok <- validate_type_code(digits) do
      validate_checksum(digits)
    end
  end

  def validate(_), do: {:error, :invalid_length}

  defp validate_type_code(<<_prefix::binary-size(2), type_code::binary-size(2), _rest::binary>>) do
    if type_code in @valid_type_codes do
      :ok
    else
      {:error, :invalid_format}
    end
  end

  defp validate_checksum(<<
         p1::binary-size(2),
         _type_code::binary-size(2),
         p2::binary-size(6),
         dv::binary-size(1)
       >>) do
    # Combine positions 1-2 and 5-10 for calculation
    payload = p1 <> p2
    calculated = calculate_dv(payload)

    if String.to_integer(dv) == calculated do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  defp calculate_dv(payload) do
    sum =
      payload
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.zip(@weights)
      |> Enum.map(fn {digit, weight} -> digit * weight end)
      |> Enum.sum()

    remainder = rem(sum, 11)

    if remainder < 2 do
      0
    else
      11 - remainder
    end
  end

  @doc """
  Formats an IE number in TO format: NN.TT.NNNNNN-N
  """
  @spec format(String.t()) :: String.t()
  def format(<<a::binary-size(2), type::binary-size(2), b::binary-size(6), d::binary-size(1)>>) do
    "#{a}.#{type}.#{b}-#{d}"
  end

  def format(digits), do: digits
end
