defmodule CurrencyTest do
  use ExUnit.Case
  doctest Currency

  test "should create a valid Currency" do
    {:ok, currency } = Currency.create("BRL", "986", 2)
    
    assert currency.code_number == "986"
    assert currency.code_alpha == "BRL"
    assert currency.exponent == 2
  end

  test "should not create a Currency with non binary code alpha" do
    {:error, message} = Currency.create(986, "986", 2)

    assert message == "Alphabetic code should be a string"
  end

  test "should not create a Currency without 3 letters" do
    {:error, message} = Currency.create("BR", "986", 2)

    assert message == "Alphabetic code should have 3 letters"
  end

  test "should not create a Currency with non binary code number" do
    {:error, message} = Currency.create("BRL", 986, 2)

    assert message == "Numeric code should be a string"
  end

  test "should not create a Currency with letter inside the code number " do
    {:error, message} = Currency.create("BRL", "A86", 2)

    assert message == "Numeric code should have only numbers"
  end

  test "should not create a Currency without 3 digits " do
    {:error, message} = Currency.create("BRL", "9876", 2)

    assert message == "Numeric code should have 3 digits"
  end

  test "should not create a Currency with non integer exponent" do
    {:error, message} = Currency.create("BRL", "986", 2.2)

    assert message == "Exponent should be an integer"
  end

  test "should not create a Currency with a negative exponent" do
    {:error, message} = Currency.create("BRL", "986", -1)

    assert message == "Exponent should be positive"
  end
end
