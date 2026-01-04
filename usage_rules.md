# Brasilex Usage Rules

## Public API

```elixir
# Boleto
Brasilex.validate_boleto(input)   # :ok | {:error, reason}
Brasilex.parse_boleto(input)      # {:ok, Boleto.t()} | {:error, reason}

# State Registration (IE)
Brasilex.validate_ie(input)       # :ok | {:error, reason}
Brasilex.parse_ie(input)          # {:ok, [IE.t()]} | {:error, reason}

# Bang variants raise Brasilex.ValidationError
Brasilex.validate_boleto!(input)
Brasilex.parse_boleto!(input)
Brasilex.validate_ie!(input)
Brasilex.parse_ie!(input)
```

## Structs

```elixir
%Brasilex.Boleto{
  type: :banking | :convenio,
  raw: String.t(),
  barcode: String.t(),
  bank_code: String.t() | nil,     # banking only
  currency_code: String.t() | nil, # banking only
  amount: Decimal.t() | nil,
  due_date: Date.t() | nil,
  segment: String.t() | nil,       # convenio only
  company_id: String.t() | nil,    # convenio only
  free_field: String.t()
}

%Brasilex.IE{
  state: atom(),        # :sp, :mg, :rj, etc.
  raw: String.t(),      # digits only
  formatted: String.t() # state-specific format
}
```

## Error Reasons

- `:invalid_length` - wrong number of digits
- `:invalid_format` - invalid characters
- `:invalid_checksum` - check digit failed
- `{:invalid_field_checksum, n}` - field n check digit failed (boleto only)
- `:unknown_type` - unrecognized format

## Notes

- `parse_ie/1` returns a **list** (some IEs match multiple states)
- `amount` is `Decimal.t()` for precision
- `nil` values are valid (amount=nil means "any amount")
- Input formatting (dots, spaces, hyphens) is stripped automatically
