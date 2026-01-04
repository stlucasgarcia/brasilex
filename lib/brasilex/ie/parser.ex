defmodule Brasilex.IE.Parser do
  @moduledoc false
  # Internal module for IE parsing.
  #
  # Validates the IE and returns a struct with state information.

  alias Brasilex.IE

  alias Brasilex.IE.States.{
    AC,
    AL,
    AM,
    AP,
    BA,
    CE,
    DF,
    ES,
    GO,
    MA,
    MG,
    MS,
    MT,
    PA,
    PB,
    PE,
    PI,
    PR,
    RJ,
    RN,
    RO,
    RR,
    RS,
    SC,
    SE,
    SP,
    TO
  }

  alias Brasilex.IE.Validator

  @state_modules %{
    ac: AC,
    al: AL,
    am: AM,
    ap: AP,
    ba: BA,
    ce: CE,
    df: DF,
    es: ES,
    go: GO,
    ma: MA,
    mg: MG,
    ms: MS,
    mt: MT,
    pa: PA,
    pb: PB,
    pe: PE,
    pi: PI,
    pr: PR,
    rj: RJ,
    rn: RN,
    ro: RO,
    rr: RR,
    rs: RS,
    sc: SC,
    se: SE,
    sp: SP,
    to: TO
  }

  @doc """
  Parses an IE and returns all possible state matches.

  Some states share identical algorithms, so a single IE may be valid for
  multiple states. This function returns a list of parsed IE structs,
  one for each matching state.
  """
  @spec parse(String.t()) :: {:ok, [IE.t()]} | {:error, atom()}
  def parse(input) when is_binary(input) do
    with {:ok, digits} <- Validator.sanitize(input),
         {:ok, states} <- Validator.detect_states(input) do
      ies =
        Enum.map(states, fn state ->
          formatted = format_for_state(digits, state)
          IE.new(state, digits, formatted)
        end)

      {:ok, ies}
    end
  end

  defp format_for_state(digits, state) do
    case Map.get(@state_modules, state) do
      nil -> digits
      module -> module.format(digits)
    end
  end
end
