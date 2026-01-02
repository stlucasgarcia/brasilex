defmodule Brasilex.Boleto.Banking.Validator do
  @moduledoc false
  # Validates boleto bancário linha digitável (47 digits) and barcode (44 digits).
  #
  # Linha digitável structure (47 digits):
  # - Field 1: positions 0-9 (includes DV at position 9) - Mod10
  # - Field 2: positions 10-20 (includes DV at position 20) - Mod10
  # - Field 3: positions 21-31 (includes DV at position 31) - Mod10
  # - Field 4: position 32 (general DV - Mod11)
  # - Field 5: positions 33-46 (due date factor + amount)
  #
  # Barcode structure (44 digits):
  # - Positions 0-3: bank code (3) + currency (1)
  # - Position 4: general DV (Mod11)
  # - Positions 5-18: due factor (4) + amount (10)
  # - Positions 19-43: free field (25)

  alias Brasilex.Checksum.{Mod10, Mod11}

  @doc """
  Validates a 47-digit boleto bancário linha digitável.
  """
  @spec validate(String.t()) :: :ok | {:error, atom() | tuple()}
  def validate(<<
        field1::binary-size(10),
        field2::binary-size(11),
        field3::binary-size(11),
        general_dv::binary-size(1),
        field5::binary-size(14)
      >>) do
    with :ok <- validate_field(field1, 1),
         :ok <- validate_field(field2, 2),
         :ok <- validate_field(field3, 3),
         :ok <- validate_general_dv(field1, field2, field3, general_dv, field5) do
      :ok
    end
  end

  def validate(_), do: {:error, :invalid_length}

  defp validate_field(field, field_num) do
    if Mod10.valid?(field) do
      :ok
    else
      {:error, {:invalid_field_checksum, field_num}}
    end
  end

  defp validate_general_dv(field1, field2, field3, dv, field5) do
    # Convert linha digitável to barcode format for Mod11 validation
    # Barcode structure: [bank_currency(4)][dv][due_factor_amount(14)][free_field(25)]
    barcode_payload = build_barcode_payload(field1, field2, field3, field5)

    if Mod11.valid?(barcode_payload, dv) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  # Builds the 43-digit barcode payload (without general DV) from linha digitável
  # for Mod11 validation
  defp build_barcode_payload(field1, field2, field3, field5) do
    # Field 1: first 4 digits = bank code (3) + currency (1)
    # Field 1: positions 4-8 = free field part 1 (5 digits)
    <<bank_currency::binary-size(4), free1::binary-size(5), _dv1::binary-size(1)>> = field1

    # Field 2: 10 digits of free field (positions 0-9, DV at position 10)
    <<free2::binary-size(10), _dv2::binary-size(1)>> = field2

    # Field 3: 10 digits of free field (positions 0-9, DV at position 10)
    <<free3::binary-size(10), _dv3::binary-size(1)>> = field3

    # Barcode payload (43 digits, without DV):
    # [bank_currency(4)][due_factor_amount(14)][free_field(25)]
    bank_currency <> field5 <> free1 <> free2 <> free3
  end

  @doc """
  Validates a 44-digit banking barcode.
  """
  @spec validate_barcode(String.t()) :: :ok | {:error, atom()}
  def validate_barcode(<<
        bank_currency::binary-size(4),
        dv::binary-size(1),
        due_factor_amount::binary-size(14),
        free_field::binary-size(25)
      >>) do
    # Barcode payload for Mod11: positions 0-3 + 5-43 (excluding DV)
    barcode_payload = bank_currency <> due_factor_amount <> free_field

    if Mod11.valid?(barcode_payload, dv) do
      :ok
    else
      {:error, :invalid_checksum}
    end
  end

  def validate_barcode(_), do: {:error, :invalid_length}
end
