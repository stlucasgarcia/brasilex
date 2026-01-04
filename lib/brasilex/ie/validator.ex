defmodule Brasilex.IE.Validator do
  @moduledoc false
  # Internal module for IE validation dispatch.
  #
  # Handles sanitization and dispatches to state-specific validators
  # based on length and prefix patterns.

  alias Brasilex.IE.States.{
    AC, AL, AM, AP, BA, CE, DF, ES, GO, MA, MG, MS, MT, PA, PB, PE, PI, PR, RJ, RN, RO, RR, RS, SC, SE, SP, TO
  }

  @doc """
  Validates an IE by trying all applicable state validators.

  Returns `:ok` if valid for any implemented state, or `{:error, reason}` otherwise.
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(input) when is_binary(input) do
    with {:ok, digits} <- sanitize(input) do
      try_validators(digits)
    end
  end

  @doc """
  Detects which state an IE belongs to by trying validators.

  Returns `{:ok, state}` if valid, or `{:error, reason}` otherwise.
  """
  @spec detect_state(String.t()) :: {:ok, atom()} | {:error, atom()}
  def detect_state(input) when is_binary(input) do
    with {:ok, digits} <- sanitize(input) do
      find_valid_state(digits)
    end
  end

  @doc """
  Detects all possible states an IE could belong to.

  Some states share identical algorithms (e.g., AM, SC, SE all use Mod11 with weights 9-2),
  making them indistinguishable by checksum alone. This function returns all matching states.

  Returns `{:ok, [state, ...]}` if valid for at least one state, or `{:error, reason}` otherwise.
  """
  @spec detect_states(String.t()) :: {:ok, [atom()]} | {:error, atom()}
  def detect_states(input) when is_binary(input) do
    with {:ok, digits} <- sanitize(input) do
      find_all_valid_states(digits)
    end
  end

  @doc """
  Removes formatting characters (dots, hyphens, slashes, spaces).
  Keeps digits and 'P' (for SP rural producer format).
  """
  @spec sanitize(String.t()) :: {:ok, String.t()} | {:error, :invalid_format | :invalid_length}
  def sanitize(input) when is_binary(input) do
    cleaned =
      input
      |> String.replace(~r/[\.\-\/\s]/, "")
      |> String.upcase()

    cond do
      not valid_format?(cleaned) ->
        {:error, :invalid_format}

      not valid_length?(cleaned) ->
        {:error, :invalid_length}

      true ->
        {:ok, cleaned}
    end
  end

  # Only digits allowed, except P at start for SP rural
  defp valid_format?(<<"P", rest::binary>>), do: String.match?(rest, ~r/^\d+$/)
  defp valid_format?(digits), do: String.match?(digits, ~r/^\d+$/)

  # Valid lengths: 8-14 digits (or P + 12 = 13 chars for SP rural)
  defp valid_length?(<<"P", rest::binary>>), do: byte_size(rest) == 12
  defp valid_length?(digits), do: byte_size(digits) in 8..14

  # Try validators in priority order (most specific prefixes first)
  defp try_validators(digits) do
    case find_valid_state(digits) do
      {:ok, _state} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Find the first state validator that accepts this IE
  # Order: specific prefixes first, then by length, then fallback
  defp find_valid_state(digits) do
    validators = get_candidate_validators(digits)

    Enum.find_value(validators, {:error, :invalid_checksum}, fn {state, module} ->
      case module.validate(digits) do
        :ok -> {:ok, state}
        {:error, _} -> nil
      end
    end)
  end

  # Find all state validators that accept this IE
  defp find_all_valid_states(digits) do
    validators = get_candidate_validators(digits)

    valid_states =
      validators
      |> Enum.filter(fn {_state, module} -> module.validate(digits) == :ok end)
      |> Enum.map(fn {state, _module} -> state end)

    if valid_states == [] do
      {:error, :invalid_checksum}
    else
      {:ok, valid_states}
    end
  end

  # Get candidate validators based on length and prefix
  defp get_candidate_validators(<<"P", _rest::binary>> = digits) when byte_size(digits) == 13 do
    [{:sp, SP}]
  end

  # 8 digits - BA or RJ
  defp get_candidate_validators(digits) when byte_size(digits) == 8 do
    [{:ba, BA}, {:rj, RJ}]
  end

  # Specific prefixes for 9 digits
  defp get_candidate_validators(<<"24", _rest::binary>> = digits) when byte_size(digits) == 9 do
    # Both RR and AL use prefix "24" - try both
    [{:rr, RR}, {:al, AL}]
  end

  defp get_candidate_validators(<<"28", _rest::binary>> = digits) when byte_size(digits) == 9 do
    [{:ms, MS}]
  end

  defp get_candidate_validators(<<"03", _rest::binary>> = digits) when byte_size(digits) == 9 do
    [{:ap, AP}]
  end

  defp get_candidate_validators(<<"12", _rest::binary>> = digits) when byte_size(digits) == 9 do
    [{:ma, MA}]
  end

  # PA prefixes: 15, 75, 76, 77, 78, 79
  defp get_candidate_validators(<<"15", _rest::binary>> = digits) when byte_size(digits) == 9 do
    [{:pa, PA}]
  end

  defp get_candidate_validators(<<"7", p::binary-size(1), _rest::binary>> = digits)
       when byte_size(digits) == 9 and p in ["5", "6", "7", "8", "9"] do
    [{:pa, PA}]
  end

  defp get_candidate_validators(<<"20", _rest::binary>> = digits) when byte_size(digits) in [9, 10] do
    [{:rn, RN}]
  end

  # 9 digits without specific prefix
  defp get_candidate_validators(digits) when byte_size(digits) == 9 do
    # GO has prefixes 10, 11, 20-29 - check these first, then fallback
    # PE eFisco (9 digits) uses 2 check digits - put after single-check validators
    [
      {:go, GO}, {:ba, BA}, {:am, AM}, {:ce, CE}, {:es, ES},
      {:pb, PB}, {:pi, PI}, {:sc, SC}, {:se, SE}, {:pe, PE}, {:ro, RO}
    ]
  end

  defp get_candidate_validators(digits) when byte_size(digits) == 10 do
    [{:rs, RS}, {:pr, PR}, {:rn, RN}]
  end

  defp get_candidate_validators(digits) when byte_size(digits) == 11 do
    [{:mt, MT}, {:to, TO}]
  end

  defp get_candidate_validators(digits) when byte_size(digits) == 12 do
    [{:sp, SP}]
  end

  # 13 digits - AC (prefix 01), DF (prefix 07), or MG
  defp get_candidate_validators(<<"01", _rest::binary>> = digits) when byte_size(digits) == 13 do
    [{:ac, AC}]
  end

  defp get_candidate_validators(<<"07", _rest::binary>> = digits) when byte_size(digits) == 13 do
    [{:df, DF}]
  end

  defp get_candidate_validators(digits) when byte_size(digits) == 13 do
    [{:mg, MG}, {:ac, AC}, {:df, DF}]
  end

  defp get_candidate_validators(digits) when byte_size(digits) == 14 do
    [{:ro, RO}, {:pe, PE}]
  end

  defp get_candidate_validators(_), do: []
end
