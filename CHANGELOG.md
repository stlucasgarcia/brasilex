# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
