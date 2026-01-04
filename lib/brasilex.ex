defmodule Brasilex do
  @moduledoc """
  Brazilian utilities for boletos, state registration, and more.

  Brasilex provides functions to validate and parse Brazilian documents,
  including boletos (bank slips) and state registration numbers (IE).

  ## Supported Features

  ### Boleto (Bank Slip)

    * **Banking Boleto** - Bank collection boletos
      - Linha digitável: 47 digits
      - Barcode: 44 digits
    * **Convenio Boleto** - Utility/tax boletos (starting with "8")
      - Linha digitável: 48 digits
      - Barcode: 44 digits

  ### State Registration (Inscrição Estadual - IE)

  Validates IE numbers for all 27 Brazilian states with auto-detection:
  AC, AL, AM, AP, BA, CE, DF, ES, GO, MA, MG, MS, MT, PA, PB, PE, PI, PR, RJ, RN, RO, RR, RS, SC, SE, SP, TO

  ## Usage

      # Validate a boleto
      Brasilex.validate_boleto("23793.38128 60000.000003 00000.000400 1 84340000019900")
      #=> :ok

      # Parse a boleto
      {:ok, boleto} = Brasilex.parse_boleto("23793.38128 60000.000003 00000.000400 1 84340000019900")
      boleto.bank_code
      #=> "237"

      # Validate a state registration (auto-detects state)
      Brasilex.validate_ie("110.042.490.114")
      #=> :ok

      # Parse a state registration (returns all matching states)
      {:ok, [ie]} = Brasilex.parse_ie("110.042.490.114")
      ie.state
      #=> :sp

  ## Error Handling

  All functions return `{:ok, result}` or `{:error, reason}` tuples,
  making them pipe-friendly and composable. Bang variants (`!`) are
  provided for convenience when exceptions are preferred.
  """

  alias Brasilex.Boleto
  alias Brasilex.IE

  # ===========================================================================
  # Boleto
  # ===========================================================================

  @doc """
  Validates a boleto linha digitável or barcode.

  See `Brasilex.Boleto.validate/1` for details.
  """
  defdelegate validate_boleto(input), to: Boleto, as: :validate

  @doc """
  Same as `validate_boleto/1` but raises on error.

  See `Brasilex.Boleto.validate!/1` for details.
  """
  defdelegate validate_boleto!(input), to: Boleto, as: :validate!

  @doc """
  Parses a boleto linha digitável or barcode.

  See `Brasilex.Boleto.parse/1` for details.
  """
  defdelegate parse_boleto(input), to: Boleto, as: :parse

  @doc """
  Same as `parse_boleto/1` but raises on error.

  See `Brasilex.Boleto.parse!/1` for details.
  """
  defdelegate parse_boleto!(input), to: Boleto, as: :parse!

  # ===========================================================================
  # State Registration (Inscrição Estadual - IE)
  # ===========================================================================

  @doc """
  Validates a State Registration (IE) number.

  See `Brasilex.IE.validate/1` for details.
  """
  defdelegate validate_ie(input), to: IE, as: :validate

  @doc """
  Same as `validate_ie/1` but raises on error.

  See `Brasilex.IE.validate!/1` for details.
  """
  defdelegate validate_ie!(input), to: IE, as: :validate!

  @doc """
  Parses a State Registration (IE) number.

  Returns all possible state matches. See `Brasilex.IE.parse/1` for details.
  """
  defdelegate parse_ie(input), to: IE, as: :parse

  @doc """
  Same as `parse_ie/1` but raises on error.

  See `Brasilex.IE.parse!/1` for details.
  """
  defdelegate parse_ie!(input), to: IE, as: :parse!
end
