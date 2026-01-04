defmodule Brasilex.IETest do
  use ExUnit.Case, async: true

  alias Brasilex.IE

  describe "validate/1" do
    test "returns :ok for valid SP IE" do
      assert :ok = IE.validate("110.042.490.114")
    end

    test "returns :ok for valid MG IE" do
      assert :ok = IE.validate("0623079040081")
    end

    test "returns :ok for IE matching multiple states" do
      assert :ok = IE.validate("820000000")
    end

    test "returns error for invalid length" do
      assert {:error, :invalid_length} = IE.validate("12345")
    end

    test "returns error for invalid format" do
      assert {:error, :invalid_format} = IE.validate("ABC123456")
    end

    test "returns error for invalid checksum" do
      assert {:error, :invalid_checksum} = IE.validate("110042490115")
    end
  end

  describe "validate!/1" do
    test "returns :ok for valid IE" do
      assert :ok = IE.validate!("110.042.490.114")
    end

    test "raises ValidationError for invalid length" do
      assert_raise Brasilex.ValidationError, ~r/Invalid length/, fn ->
        IE.validate!("12345")
      end
    end

    test "raises ValidationError for invalid format" do
      assert_raise Brasilex.ValidationError, ~r/Invalid format/, fn ->
        IE.validate!("ABC123456")
      end
    end

    test "raises ValidationError for invalid checksum" do
      assert_raise Brasilex.ValidationError, ~r/Invalid check digit/, fn ->
        IE.validate!("110042490115")
      end
    end
  end

  describe "parse/1" do
    test "returns list with single IE for unique state match" do
      assert {:ok, [ie]} = IE.parse("110.042.490.114")
      assert ie.state == :sp
      assert ie.raw == "110042490114"
      assert ie.formatted == "110.042.490.114"
    end

    test "returns list with multiple IEs for shared algorithms" do
      assert {:ok, ies} = IE.parse("820000000")
      assert length(ies) > 1

      states = Enum.map(ies, & &1.state)
      assert :am in states
      assert :sc in states
      assert :se in states
    end

    test "each IE has correct state-specific formatting" do
      assert {:ok, ies} = IE.parse("820000000")

      am_ie = Enum.find(ies, &(&1.state == :am))
      assert am_ie.formatted == "82.000.000-0"

      sc_ie = Enum.find(ies, &(&1.state == :sc))
      assert sc_ie.formatted == "820.000.000"
    end

    test "returns error for invalid length" do
      assert {:error, :invalid_length} = IE.parse("12345")
    end

    test "returns error for invalid format" do
      assert {:error, :invalid_format} = IE.parse("ABC123456")
    end

    test "returns error for invalid checksum" do
      assert {:error, :invalid_checksum} = IE.parse("110042490115")
    end
  end

  describe "parse!/1" do
    test "returns list of IEs for valid input" do
      ies = IE.parse!("110.042.490.114")
      assert [ie] = ies
      assert ie.state == :sp
    end

    test "raises ValidationError for invalid length" do
      assert_raise Brasilex.ValidationError, ~r/Invalid length/, fn ->
        IE.parse!("12345")
      end
    end

    test "raises ValidationError for invalid format" do
      assert_raise Brasilex.ValidationError, ~r/Invalid format/, fn ->
        IE.parse!("ABC123456")
      end
    end

    test "raises ValidationError for invalid checksum" do
      assert_raise Brasilex.ValidationError, ~r/Invalid check digit/, fn ->
        IE.parse!("110042490115")
      end
    end
  end

  describe "new/3" do
    test "creates IE struct with all fields" do
      ie = IE.new(:sp, "110042490114", "110.042.490.114")
      assert ie.state == :sp
      assert ie.raw == "110042490114"
      assert ie.formatted == "110.042.490.114"
    end

    test "defaults formatted to raw when not provided" do
      ie = IE.new(:sp, "110042490114")
      assert ie.formatted == "110042490114"
    end
  end
end
