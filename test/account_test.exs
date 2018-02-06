defmodule AccountTest do
  use ExUnit.Case
  doctest Account

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, zero} = Money.create(0, brl)
    %{brl: brl, zero: zero}
  end

  test "should create a valid account with no limit", context do
    zero = context.zero
    brl = context.brl

    assert {:ok, {1, "Evaldo Bratti", ^zero, ^brl}} = Account.create(1, "Evaldo Bratti", zero)
  end

  test "should not create account with no owner name", context do
    zero = context.zero

    assert {:error, "Name should not be nil"} = Account.create(1, nil, zero)
  end

  test "should not create account with non string owner name", context do
    zero = context.zero

    assert {:error, "Name should be a string"} = Account.create(1, 1, zero)
  end

  test "should not create account with empty name", context do
    zero = context.zero

    assert {:error, "Name should not be empty"} = Account.create(1, "", zero)
  end

  test "limit should not be negative", context do
    brl = context.brl
    {:ok, negative_money} = Money.create(-1, brl)

    assert {:error, "Limit should not be negative"} = Account.create(1, "Evaldo Bratti", negative_money)
  end
end