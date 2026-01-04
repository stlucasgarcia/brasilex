# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-01-04

### Added

- **State Registration (Inscrição Estadual - IE)** validation and parsing
  - `Brasilex.validate_ie/1` - Validate IE number
  - `Brasilex.validate_ie!/1` - Validate with exception on error
  - `Brasilex.parse_ie/1` - Parse IE into structured data (returns all matching states)
  - `Brasilex.parse_ie!/1` - Parse with exception on error
  - Support for all 27 Brazilian states: AC, AL, AM, AP, BA, CE, DF, ES, GO, MA, MG, MS, MT, PA, PB, PE, PI, PR, RJ, RN, RO, RR, RS, SC, SE, SP, TO
  - Auto-detection of state based on length, prefix, and checksum algorithm
  - State-specific formatting for parsed IEs
  - `Brasilex.IE` struct with `:state`, `:raw`, and `:formatted` fields

### Changed

- **Breaking:** `parse_ie/1` returns `{:ok, [IE.t()]}` (list of all matching states) instead of a single IE
  - Some states share identical validation algorithms, making them indistinguishable
  - Example: `Brasilex.parse_ie("820000000")` returns IEs for `:am`, `:sc`, `:se`
- Refactored main `Brasilex` module to delegate to `Brasilex.Boleto` and `Brasilex.IE`
  - Functions are now also available directly: `Brasilex.Boleto.validate/1`, `Brasilex.IE.parse/1`
- Internal code improvements:
  - Replaced 27 `format_for_state/2` function clauses with a module map
  - Removed redundant regex validation in boleto sanitization

## [0.1.2] - 2026-01-02

### Changed

- **Breaking:** `amount` field now returns `Decimal.t()` instead of `float()`
  - Provides precise monetary calculations without floating-point errors
  - Use `Decimal.equal?/2` for comparisons
  - Added `decimal ~> 2.0` as a dependency

## [0.1.1] - 2026-01-02

### Added

- FEBRABAN due date factor rollover support (2025-02-22 transition)
  - Old cycle: base 1997-10-07, factor 9999 = 2025-02-21
  - New cycle: base 2022-05-29, factor 1000 = 2025-02-22
  - Auto-detects cycle based on calculated date reasonableness

## [0.1.0] - 2026-01-02

### Added

- Initial release of Brasilex - Brazilian boleto parser and validator
- `Brasilex.validate_boleto/1` - Validate boleto linha digitável or barcode
- `Brasilex.validate_boleto!/1` - Validate with exception on error
- `Brasilex.parse_boleto/1` - Parse boleto into structured data
- `Brasilex.parse_boleto!/1` - Parse with exception on error
- Support for **Banking Boletos**
  - Linha digitável (47 digits)
  - Barcode (44 digits)
  - Bank code extraction
  - Currency code extraction
  - Amount parsing (in reais)
  - Due date calculation from factor
  - Free field extraction
- Support for **Convenio Boletos**
  - Linha digitável (48 digits starting with "8")
  - Barcode (44 digits starting with "8")
  - Segment identification
  - Amount parsing (in reais)
  - Company ID extraction
  - Free field extraction
- `Brasilex.Boleto` struct with helper functions:
  - `Brasilex.Boleto.banking?/1`
  - `Brasilex.Boleto.convenio?/1`
- `Brasilex.ValidationError` exception for bang functions
- Checksum algorithms:
  - Modulo 10 (field-level validation)
  - Modulo 11 (general barcode validation)
- Input sanitization (strips dots, spaces, hyphens)
- Full typespec coverage
- Comprehensive test suite
