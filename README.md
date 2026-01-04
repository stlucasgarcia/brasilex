<div align="center">
<h1>Brasilex</h1>

<p>Elixir library for Brazilian utilities and helpers.</p>

[![Hex.pm](https://img.shields.io/hexpm/v/brasilex.svg)](https://hex.pm/packages/brasilex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/brasilex)
[![License](https://img.shields.io/hexpm/l/brasilex.svg)](https://github.com/stlucasgarcia/brasilex/blob/main/LICENSE)

</div>

## Features

### Boleto (Bank Slip)

- [x] **Validate** boleto linha digitável (typeable line) and barcode
- [x] **Parse** boleto data into structured format
- [x] **Banking Boletos** - Bank collection boletos
  - Linha digitável: 47 digits
  - Barcode: 44 digits
- [x] **Convenio Boletos** - Utility/tax boletos (starting with "8")
  - Linha digitável: 48 digits
  - Barcode: 44 digits

### State Registration (Inscrição Estadual - IE)

- [x] **Validate** IE numbers with auto-detection
- [x] **Parse** IE into structured data with state-specific formatting
- [x] **All 27 states** supported: AC, AL, AM, AP, BA, CE, DF, ES, GO, MA, MG, MS, MT, PA, PB, PE, PI, PR, RJ, RN, RO, RR, RS, SC, SE, SP, TO
- [x] **Multiple state detection** - Returns all states that match when algorithms overlap

### General

- [x] Full typespec coverage
- [x] Comprehensive test suite

## Roadmap

Upcoming features for future releases:

- [ ] **CPF** - Validate, format, and generate CPF numbers
- [ ] **CNPJ** - Validate, format, and generate CNPJ numbers
- [ ] **CEP** - Validate and format postal codes
- [ ] **Phone** - Validate and format Brazilian phone numbers
- [ ] **PIS/PASEP** - Validate social security numbers
- [ ] **Vehicle Plate** - Validate traditional and Mercosul formats
- [ ] **CNH** - Validate driver's license numbers
- [ ] **RENAVAM** - Validate vehicle registration numbers
- [ ] **Currency** - Format BRL currency values

## Installation

Add `brasilex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:brasilex, "~> 0.2.0"}
  ]
end
```

Then run:

    $ mix deps.get

## Usage

### Validate a Boleto

```elixir
# Returns :ok or {:error, reason}
Brasilex.validate_boleto("00190.00009 01234.567890 12345.678908 1 00000000000000")
#=> :ok

Brasilex.validate_boleto("invalid")
#=> {:error, :invalid_length}

# Bang version raises on error
Brasilex.validate_boleto!("00190.00009 01234.567890 12345.678908 1 00000000000000")
#=> :ok

Brasilex.validate_boleto!("invalid")
#=> ** (Brasilex.ValidationError) Invalid length: wrong number of digits
```

### Parse a Boleto

```elixir
{:ok, boleto} = Brasilex.parse_boleto("00190000090123456789012345678908100000000000000")

boleto.type        #=> :banking
boleto.bank_code   #=> "001"
boleto.amount      #=> Decimal.new("150.00") or nil
boleto.due_date    #=> ~D[2020-07-04] or nil
boleto.barcode     #=> "00191000000000000001234567890123456789080"

# Bang version raises on error
boleto = Brasilex.parse_boleto!("00190000090123456789012345678908100000000000000")
```

### Input Formats

The library accepts both linha digitável and barcode, with or without formatting:

```elixir
# Linha digitável with dots, spaces, hyphens
Brasilex.validate_boleto("00190.00009 01234.567890 12345.678908 1 00000000000000")

# Linha digitável digits only (47 or 48 digits)
Brasilex.validate_boleto("00190000090123456789012345678908100000000000000")

# Barcode (44 digits)
Brasilex.validate_boleto("23791843400000199003812860000000003000000004")
```

## Boleto Types

### Banking Boleto (47 digits)

Bank collection boletos used for payments, invoices, etc.

```elixir
{:ok, boleto} = Brasilex.parse_boleto("23793.38128 60000.000003 00000.000400 1 84340000019900")

boleto.type          #=> :banking
boleto.bank_code     #=> "237" (e.g., "001" = Banco do Brasil)
boleto.currency_code #=> "9" (BRL)
boleto.amount        #=> Decimal.new("199.00") or nil if any amount
boleto.due_date      #=> ~D[2020-07-04] or nil if no due date
boleto.free_field    #=> "3812860000000003000000004" (25 digits of bank-defined content)
```

### Convenio Boleto (48 digits)

Utility bills, taxes, and government collections. First digit is always "8".

```elixir
{:ok, boleto} = Brasilex.parse_boleto("846700000005 573200481018 150820204176 494672890166")

boleto.type       #=> :convenio
boleto.segment    #=> "6" (determines validation algorithm)
boleto.amount     #=> Decimal.new("573.20") or nil
boleto.company_id #=> "0481018150820204176494672890166"
boleto.free_field #=> Segment-specific content
```

## State Registration (IE)

### Validate an IE

```elixir
# Returns :ok or {:error, reason}
Brasilex.validate_ie("110.042.490.114")
#=> :ok

Brasilex.validate_ie("12345")
#=> {:error, :invalid_length}

# Bang version raises on error
Brasilex.validate_ie!("110.042.490.114")
#=> :ok
```

### Parse an IE

```elixir
# Returns all states that match the IE
{:ok, [ie]} = Brasilex.parse_ie("110.042.490.114")

ie.state      #=> :sp
ie.raw        #=> "110042490114"
ie.formatted  #=> "110.042.490.114"

# Some IEs are valid for multiple states (shared algorithms)
{:ok, ies} = Brasilex.parse_ie("820000000")
Enum.map(ies, & &1.state)
#=> [:am, :sc, :se]

# Each IE has state-specific formatting
am_ie = Enum.find(ies, & &1.state == :am)
am_ie.formatted  #=> "82.000.000-0"

sc_ie = Enum.find(ies, & &1.state == :sc)
sc_ie.formatted  #=> "820.000.000"
```

### Supported States

All 27 Brazilian states are supported with their specific validation rules:

| State | Digits | Algorithm | Notes |
|-------|--------|-----------|-------|
| AC | 13 | Mod11 (2 DVs) | Prefix "01" |
| AL | 9 | Mod11 | Prefix "24", type codes 0,3,5,7,8 |
| AM | 9 | Mod11 | Special case when sum < 11 |
| AP | 9 | Mod11 | Prefix "03", special p/d values |
| BA | 8-9 | Mod10/Mod11 | Based on first digit |
| CE | 9 | Mod11 | Weights 9-2 |
| DF | 13 | Mod11 (2 DVs) | Prefix "07" |
| ES | 9 | Mod11 | Weights 9-2 |
| GO | 9 | Mod11 | Prefixes 10, 11, 20-29 |
| MA | 9 | Mod11 | Prefix "12" |
| MG | 13 | Mod10 + Mod11 | 2 check digits |
| MS | 9 | Mod11 | Prefix "28" |
| MT | 11 | Mod11 | Single DV |
| PA | 9 | Mod11 | Prefixes 15, 75-79 |
| PB | 9 | Mod11 | Weights 9-2 |
| PE | 9/14 | Mod11 | eFisco (9) or CACEPE (14) |
| PI | 9 | Mod11 | Weights 9-2 |
| PR | 10 | Mod11 (2 DVs) | Weights 3,2,7,6,5,4,3,2 |
| RJ | 8 | Mod11 | Weights 2,7,6,5,4,3,2 |
| RN | 9-10 | Mod11 | Prefix "20" |
| RO | 9/14 | Mod11 | Legacy (9) or new (14) |
| RR | 9 | Mod9 | Prefix "24" |
| RS | 10 | Mod11 | Single DV |
| SC | 9 | Mod11 | Weights 9-2 |
| SE | 9 | Mod11 | Weights 9-2 |
| SP | 12/13 | Custom | Regular (12) or rural "P" (13) |
| TO | 11 | Mod11 | Type codes 01, 02, 03, 99 |

## Error Handling

All functions return `{:ok, result}` or `{:error, reason}` tuples:

```elixir
case Brasilex.validate_boleto(input) do
  :ok ->
    IO.puts("Valid boleto!")

  {:error, :invalid_length} ->
    IO.puts("Wrong number of digits (expected 47 or 48)")

  {:error, :invalid_format} ->
    IO.puts("Invalid characters found")

  {:error, :invalid_checksum} ->
    IO.puts("General check digit validation failed")

  {:error, {:invalid_field_checksum, n}} ->
    IO.puts("Field #{n} check digit validation failed")

  {:error, :unknown_type} ->
    IO.puts("Could not determine boleto type")
end
```

### Bang Variants

Bang variants raise `Brasilex.ValidationError` for cleaner pipelines:

```elixir
try do
  boleto = Brasilex.parse_boleto!("invalid")
  # Process boleto...
rescue
  e in Brasilex.ValidationError ->
    IO.puts("Validation failed: #{e.message}")
end
```

## Response Types with Structs

For better type safety and developer experience, Brasilex provides struct definitions:

```elixir
# Boleto struct with all parsed fields
{:ok, %Brasilex.Boleto{} = boleto} = Brasilex.parse_boleto("...")

# Banking boleto fields
boleto.type          #=> :banking
boleto.bank_code     #=> String.t()
boleto.currency_code #=> String.t()
boleto.amount        #=> Decimal.t() | nil
boleto.due_date      #=> Date.t() | nil
boleto.free_field    #=> String.t()
boleto.barcode       #=> String.t()

# Convenio boleto fields
boleto.type       #=> :convenio
boleto.segment    #=> String.t()
boleto.amount     #=> Decimal.t() | nil
boleto.company_id #=> String.t()
boleto.free_field #=> String.t()
boleto.barcode    #=> String.t()

# IE struct with parsed fields
{:ok, [%Brasilex.IE{} = ie]} = Brasilex.parse_ie("110.042.490.114")

ie.state      #=> :sp
ie.raw        #=> "110042490114"
ie.formatted  #=> "110.042.490.114"
```

### Available Structs

| Struct                     | Description                                               |
| -------------------------- | --------------------------------------------------------- |
| `Brasilex.Boleto`          | Parsed boleto with all fields (type, amount, dates, etc.) |
| `Brasilex.IE`              | Parsed state registration with state, raw, and formatted  |
| `Brasilex.ValidationError` | Exception raised by bang functions                        |

## Validation Details

### Check Digit Algorithms

Brasilex validates boletos using the standard Brazilian algorithms:

- **Banking boletos (47 digits)**: Module 10 for field check digits, Module 11 for general verifier
- **Convenio boletos (48 digits)**: Module 10 or Module 11 depending on segment identifier

### What Gets Validated

1. **Length**: Must be exactly 44, 47, or 48 digits (after removing formatting)
2. **Format**: Must contain only digits (after removing dots, spaces, hyphens)
3. **Check digits**: All field-level and general check digits are verified
4. **Type detection**: Boleto type is determined from digit count and first character
   - 44 digits starting with "8" → Convenio barcode
   - 44 digits (other) → Banking barcode
   - 47 digits → Banking linha digitável
   - 48 digits starting with "8" → Convenio linha digitável

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stlucasgarcia/brasilex.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

The library is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
