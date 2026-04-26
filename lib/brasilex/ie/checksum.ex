defmodule Brasilex.IE.Checksum do
  @moduledoc false
  # Shared building blocks for Brazilian state registration (IE) checksums.
  #
  # All 27 states share the same "weighted-sum then post-process" pipeline.
  # This module exposes that pipeline so each state validator only declares
  # what is genuinely state-specific (weight vector and special-case rule).

  @doc """
  Sums the products of each digit and its corresponding weight.

  Iterates left-to-right; weights align to digits in order. Extra digits or
  weights are silently dropped (`Enum.zip/2` semantics).
  """
  @spec weighted_sum(String.t(), [integer()]) :: integer()
  def weighted_sum(digits, weights) when is_binary(digits) and is_list(weights) do
    digits
    |> :binary.bin_to_list()
    |> Enum.zip(weights)
    |> Enum.reduce(0, fn {char, weight}, acc -> acc + (char - ?0) * weight end)
  end

  @doc """
  Computes a Mod 11 check digit for the given payload + weights.

  Rule variants for the post-modulo special case:

    * `:zero_when_le_1` — if `rem(sum, 11)` is 0 or 1, returns 0;
      otherwise `11 - rem(sum, 11)`. The most common variant.

    * `:subtract_10_when_gt_9` — `11 - rem(sum, 11)`, but if the result
      would be 10 or 11, returns `result - 10`. Used by RO and PE legacy.

    * `:rem_times_10_zero_when_10` — `rem(sum * 10, 11)`; if the result
      is 10, returns 0. Used by AL and RN.

  """
  @spec mod11_dv(String.t(), [integer()], atom()) :: non_neg_integer()
  def mod11_dv(digits, weights, rule \\ :zero_when_le_1) do
    digits
    |> weighted_sum(weights)
    |> apply_rule(rule)
  end

  defp apply_rule(sum, :zero_when_le_1) do
    case rem(sum, 11) do
      r when r in [0, 1] -> 0
      r -> 11 - r
    end
  end

  defp apply_rule(sum, :subtract_10_when_gt_9) do
    result = 11 - rem(sum, 11)
    if result > 9, do: result - 10, else: result
  end

  defp apply_rule(sum, :rem_times_10_zero_when_10) do
    case rem(sum * 10, 11) do
      10 -> 0
      r -> r
    end
  end

  @doc """
  Sums the digits of a non-negative integer (e.g., 12 -> 1 + 2 = 3).

  Used by MG's D1 calculation, where two-digit products are reduced
  before summing.
  """
  @spec digit_sum(non_neg_integer()) :: non_neg_integer()
  def digit_sum(n) when n < 10, do: n
  def digit_sum(n), do: rem(n, 10) + digit_sum(div(n, 10))
end
