defmodule Brasilex.Boleto.Convenio.Validator do
  @moduledoc false
  # Validates boleto de convênio linha digitável (48 digits) and barcode (44 digits).
  #
  # Linha digitável structure: 4 fields of 12 digits each (11 payload + 1 DV)
  # Barcode structure: 44 digits (4 x 11, no field DVs)
  #
  # Convenio boleto positions:
  # - Position 0: "8" (product ID - arrecadação)
  # - Position 1: segment (identifies type of service)
  # - Position 2: value type (determines checksum algorithm)
  #   - 6, 7: effective value, Mod 10
  #   - 8, 9: reference value, Mod 10
  #   - Others: Mod 11
  # - Position 3: general DV
  # - Positions 4+: value and company/free data

  alias Brasilex.Checksum.{Mod10, Mod11}

  @doc """
  Validates a 48-digit boleto de convênio linha digitável.
  """
  @spec validate(String.t()) :: :ok | {:error, atom() | tuple()}
  def validate(
        <<"8", _segment::binary-size(1), value_type::binary-size(1), _rest::binary>> = digits
      )
      when byte_size(digits) == 48 do
    mod_type = get_mod_type(value_type)
    validate_fields(digits, mod_type)
  end

  def validate(_), do: {:error, :invalid_length}

  # Determines which modulo algorithm to use based on the value type digit
  # Value type 6, 7: Mod10 (effective value)
  # Value type 8, 9: Mod11 (reference value)
  # Others: Mod11
  defp get_mod_type(value_type) when value_type in ["6", "7"], do: :mod10
  defp get_mod_type(_), do: :mod11

  # Validates all 4 fields using the appropriate modulo algorithm
  defp validate_fields(digits, mod_type) do
    fields = for i <- 0..3, do: binary_part(digits, i * 12, 12)

    fields
    |> Enum.with_index(1)
    |> Enum.reduce_while(:ok, fn {field, num}, :ok ->
      if valid_field?(field, mod_type) do
        {:cont, :ok}
      else
        {:halt, {:error, {:invalid_field_checksum, num}}}
      end
    end)
  end

  # Validates a single field with Mod10 (last digit is DV)
  defp valid_field?(field, :mod10), do: Mod10.valid?(field)

  # Validates a single field with Mod11 convenio variant (last digit is DV)
  # Uses convenio Mod11 which maps 0, 10, 11 → 0 (different from banking)
  defp valid_field?(<<payload::binary-size(11), dv::binary-size(1)>>, :mod11) do
    Mod11.valid_convenio?(payload, dv)
  end

  @doc """
  Validates a 44-digit convenio barcode.
  """
  @spec validate_barcode(String.t()) :: :ok | {:error, atom()}
  def validate_barcode(
        <<"8", _segment::binary-size(1), value_type::binary-size(1), dv::binary-size(1),
          _rest::binary-size(40)>> = digits
      )
      when byte_size(digits) == 44 do
    mod_type = get_mod_type(value_type)

    # Build payload for DV validation: positions 0-2 + 4-43 (excluding DV at position 3)
    <<"8", header::binary-size(2), _dv::binary-size(1), payload::binary>> = digits
    barcode_payload = "8" <> header <> payload

    valid =
      case mod_type do
        :mod10 ->
          # For Mod10, the DV is calculated on the full payload
          expected = Mod10.calculate(barcode_payload)
          dv == Integer.to_string(expected)

        :mod11 ->
          # Use convenio variant of Mod11 (maps 0, 10, 11 → 0)
          Mod11.valid_convenio?(barcode_payload, dv)
      end

    if valid do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  def validate_barcode(_), do: {:error, :invalid_length}
end
