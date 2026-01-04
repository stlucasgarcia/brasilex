defmodule Brasilex.IE do
  @moduledoc """
  Struct and functions for State Registration (Inscrição Estadual) validation.

  ## Fields

    * `:state` - The Brazilian state code as an atom (e.g., `:sp`, `:mg`)
    * `:raw` - The IE number with only digits (and P for SP rural)
    * `:formatted` - The IE number with state-specific formatting

  ## Example

      iex> {:ok, ies} = Brasilex.IE.parse("110.042.490.114")
      iex> [ie] = ies
      iex> ie.state
      :sp
      iex> ie.raw
      "110042490114"
      iex> ie.formatted
      "110.042.490.114"

  """

  alias Brasilex.IE.Parser
  alias Brasilex.IE.Validator
  alias Brasilex.ValidationError

  @enforce_keys [:state, :raw]
  defstruct [:state, :raw, :formatted]

  @type validation_error ::
          :invalid_length
          | :invalid_format
          | :invalid_checksum
          | :unknown_type

  @type t :: %__MODULE__{
          state: atom(),
          raw: String.t(),
          formatted: String.t() | nil
        }

  @doc """
  Creates a new IE struct.
  """
  @spec new(atom(), String.t(), String.t() | nil) :: t()
  def new(state, raw, formatted \\ nil) do
    %__MODULE__{
      state: state,
      raw: raw,
      formatted: formatted || raw
    }
  end

  @doc """
  Validates a State Registration (Inscrição Estadual - IE) number.

  The state is auto-detected based on the IE format, length, and prefix.
  Supports all 27 Brazilian states.

  Returns `:ok` if valid for at least one state, or `{:error, reason}` if invalid.

  ## Examples

      iex> Brasilex.IE.validate("110.042.490.114")
      :ok

      iex> Brasilex.IE.validate("12345")
      {:error, :invalid_length}

  ## Error Reasons

    * `:invalid_length` - Wrong number of digits (expected 8-14)
    * `:invalid_format` - Contains invalid characters
    * `:invalid_checksum` - Check digit validation failed for all candidate states

  """
  @spec validate(String.t()) :: :ok | {:error, validation_error()}
  def validate(input) when is_binary(input) do
    Validator.validate(input)
  end

  @doc """
  Same as `validate/1` but raises `Brasilex.ValidationError` on error.

  ## Examples

      iex> Brasilex.IE.validate!("12345")
      ** (Brasilex.ValidationError) Invalid length: wrong number of digits

  """
  @spec validate!(String.t()) :: :ok
  def validate!(input) when is_binary(input) do
    case validate(input) do
      :ok -> :ok
      {:error, reason} -> raise ValidationError, reason: reason
    end
  end

  @doc """
  Parses a State Registration (Inscrição Estadual - IE) number.

  Returns all possible state matches, since some states share identical
  validation algorithms (e.g., AM, SC, SE all use Mod11 with weights 9-2).

  ## Examples

      # IE valid for multiple states
      iex> {:ok, ies} = Brasilex.IE.parse("820000000")
      iex> Enum.map(ies, & &1.state)
      [:am, :sc, :se]

      # IE valid for single state
      iex> {:ok, [ie]} = Brasilex.IE.parse("110.042.490.114")
      iex> ie.state
      :sp
      iex> ie.raw
      "110042490114"
      iex> ie.formatted
      "110.042.490.114"

  ## Parsed Fields

    * `:state` - The detected state as an atom (e.g., `:sp`, `:mg`)
    * `:raw` - The IE number with only digits
    * `:formatted` - The IE number with state-specific formatting

  """
  @spec parse(String.t()) :: {:ok, [t()]} | {:error, validation_error()}
  def parse(input) when is_binary(input) do
    Parser.parse(input)
  end

  @doc """
  Same as `parse/1` but raises `Brasilex.ValidationError` on error.

  ## Examples

      iex> Brasilex.IE.parse!("12345")
      ** (Brasilex.ValidationError) Invalid length: wrong number of digits

  """
  @spec parse!(String.t()) :: [t()]
  def parse!(input) when is_binary(input) do
    case parse(input) do
      {:ok, ies} -> ies
      {:error, reason} -> raise ValidationError, reason: reason
    end
  end
end
