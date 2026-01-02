# Brasilex Usage Rules

## What This Library Does

Brasilex validates and parses Brazilian boletos (both linha digitável and barcode).

- **Banking boletos**: 47 digits (linha digitável) or 44 digits (barcode)
- **Convenio boletos**: 48 digits starting with "8" (linha digitável) or 44 digits starting with "8" (barcode)

## Public API

Only use these functions from the `Brasilex` module:

```elixir
# Validation - returns :ok or {:error, reason}
Brasilex.validate_boleto(input)
Brasilex.validate_boleto!(input)  # raises on error

# Parsing - returns {:ok, %Brasilex.Boleto{}} or {:error, reason}
Brasilex.parse_boleto(input)
Brasilex.parse_boleto!(input)  # raises on error
```

## Input Format

Input accepts linha digitável or barcode, formatted or unformatted:

```elixir
# Linha digitável with formatting - dots, spaces, hyphens are stripped
"23793.38128 60000.000003 00000.000400 1 84340000019900"

# Linha digitável without formatting (47 or 48 digits)
"23793381286000000000300000000400184340000019900"

# Barcode (44 digits)
"23791843400000199003812860000000003000000004"
```

## Boleto Struct Fields

```elixir
%Brasilex.Boleto{
  type: :banking | :convenio,
  raw: String.t(),           # sanitized input
  barcode: String.t(),       # 44-digit barcode
  bank_code: String.t(),     # banking only, e.g., "237"
  currency_code: String.t(), # banking only, "9" = BRL
  amount: float() | nil,     # reais (e.g., 150.00), nil if unspecified
  due_date: Date.t() | nil,  # nil if unspecified
  segment: String.t(),       # convenio only
  company_id: String.t(),    # convenio only
  free_field: String.t()     # bank/company defined content
}
```

## Error Reasons

- `:invalid_length` - not 44, 47, or 48 digits
- `:invalid_format` - empty input
- `:invalid_checksum` - general check digit failed
- `{:invalid_field_checksum, n}` - field n (1-4) check digit failed (linha digitável only)
- `:unknown_type` - 48 digits not starting with "8", or unrecognized format

## Type Detection

| Digits | First Digit | Type |
|--------|-------------|------|
| 44 | "8" | Convenio barcode |
| 44 | Other | Banking barcode |
| 47 | Any | Banking linha digitável |
| 48 | "8" | Convenio linha digitável |

## Common Mistakes

1. **Don't access internal modules** - only use `Brasilex.*` functions
2. **Amount is already in reais** - no need to divide (e.g., 150.00 means R$ 150,00)
3. **nil values are valid** - amount=nil means "any amount", due_date=nil means "no due date"
4. **Always handle errors** - invalid boletos are common in user input
