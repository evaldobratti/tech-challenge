defmodule MoneyTest do
  use ExUnit.Case
  doctest Money

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, usd} = Currency.create("USD", "840", 2, "$")
    %{brl: brl, usd: usd}
  end

  test "should create one BRL", context do
    {:ok, {integer, exponent, currency}} = Money.create(1, context.brl)

    assert integer == 1
    assert exponent == 0
    assert currency == context.brl
  end

  test "should create floating point BRL", context do
    {:ok, {integer, exponent, currency}} = Money.create(1.39, context.brl)

    assert integer == 1
    assert exponent == 39
    assert currency == context.brl
  end

  test "should not create money without currency" do
    {:error, message} = Money.create(1, nil)

    assert message == "Currency is not present"
  end

  test "should create negative money", context do
    {:ok, {integer, exponent, currency}} = Money.create(-1.42, context.brl)

    assert integer == -1
    assert exponent == -42
    assert currency == context.brl
  end

  test "should not sum money from different currencies", context do
    {:ok, oneReal} = Money.create(1, context.brl)
    {:ok, oneDollar} = Money.create(1, context.usd)

    {:error, message} = Money.sum(oneReal, oneDollar)

    assert message == "You can only sum money from the same currency"
  end

  test "should sum integer amount from same currencies", context do
    {:ok, oneReal} = Money.create(1, context.brl)

    {:ok, sum} = Money.sum(oneReal, oneReal)
    {integer, exponent, currency} = sum

    assert integer == 2
    assert exponent == 0
    assert currency == context.brl
  end

  test "should sum exponent amount from same currencies", context do
    {:ok, fourtyCents} = Money.create(0.40, context.brl)

    {:ok, sum} = Money.sum(fourtyCents, fourtyCents)
    {integer, exponent, currency} = sum

    assert integer == 0
    assert exponent == 80
    assert currency == context.brl
  end

  test "should sum exponent amount and transfer it to integer part when it surpasses exponent from the currency",
       context do
    {:ok, sixtyCents} = Money.create(0.60, context.brl)

    {:ok, sum} = Money.sum(sixtyCents, sixtyCents)
    {integer, exponent, currency} = sum

    assert integer == 1
    assert exponent == 20
    assert currency == context.brl
  end

  test "should sum integer from one and exponent from another", context do
    {:ok, oneReal} = Money.create(1, context.brl)
    {:ok, sixtyCents} = Money.create(0.60, context.brl)

    {:ok, sum} = Money.sum(oneReal, sixtyCents)
    {integer, exponent, currency} = sum

    assert integer == 1
    assert exponent == 60
    assert currency == context.brl
  end

  test "should change signal on negative", context do
    {:ok, money} = Money.create(1.50, context.brl)

    negative = Money.negative(money)
    {integer, exponent, currency} = negative

    assert integer == -1
    assert exponent == -50
    assert currency == context.brl
  end

  test "should sum positive and negative moneys", context do
    {:ok, five_reais} = Money.create(5, context.brl)
    {:ok, three_half_reais} = Money.create(-3.5, context.brl)

    {:ok, sum} = Money.sum(five_reais, three_half_reais)
    {integer, exponent, currency} = sum

    assert integer == 1
    assert exponent == 50
    assert currency == context.brl
  end

  test "should sum positive exponent with negative exponent", context do
    {:ok, positive_exponent} = Money.create(0.23, context.brl)
    {:ok, negative_exponent} = Money.create(-0.47, context.brl)

    {:ok, sum} = Money.sum(positive_exponent, negative_exponent)
    {integer, exponent, currency} = sum

    assert integer == 0
    assert exponent == -24
    assert currency == context.brl
  end

  test "should sum negative moneys", context do
    {:ok, minusOneHalfReais} = Money.create(-1.54, context.brl)

    {:ok, sum} = Money.sum(minusOneHalfReais, minusOneHalfReais)
    {integer, exponent, currency} = sum

    assert integer == -3
    assert exponent == -8
    assert currency == context.brl
  end

  test "should format money with currency on to_string", context do
    {:ok, oneHalfReais} = Money.create(-1.50, context.brl)

    assert Money.to_string(oneHalfReais) == "R$ -1.50"
  end

  test "should not exchange same currency if rate is not 1", context do
    brl = context.brl

    {:ok, money_brl} = Money.create(1, brl)

    {:error, message} = Money.exchange(money_brl, brl, 2)

    assert message == "Exchanging from to the same currency should have 1 as rate"
  end

  test "should exchange dollars to reais at 2 rate", context do
    %{brl: brl, usd: usd} = context

    {:ok, money_usd} = Money.create(1, usd)

    {:ok, {integer, exponent, currency}, {leftover, leftover_currency}} =
      Money.exchange(money_usd, brl, 2)

    assert integer == 2
    assert exponent == 0
    assert currency == brl
    assert leftover == 0
    assert leftover_currency == brl
  end

  test "should exchange dollars to reais at 2.5555 rate", context do
    %{brl: brl, usd: usd} = context

    {:ok, money_usd} = Money.create(1, usd)

    {:ok, {integer, exponent, currency}, {leftover, _}} = Money.exchange(money_usd, brl, 2.5555)

    assert integer == 2
    assert exponent == 55
    assert currency == brl
    assert leftover == 55000
  end

  test "should exchange reais to dollars at 0.3143 rate", context do
    %{brl: brl, usd: usd} = context

    {:ok, money_brl} = Money.create(1, brl)

    {:ok, {integer, exponent, currency}, {leftover, _}} = Money.exchange(money_brl, usd, 0.3143)

    assert integer == 0
    assert exponent == 31
    assert currency == usd
    assert leftover == 43000
  end

  test "should divide $ 1 equally by 2", context do
    usd = context.usd
    {:ok, money} = Money.create(1, usd)

    parts = Money.divide(money, 2)

    assert {0, 50, ^usd} = Enum.at(parts, 0)
    assert {0, 50, ^usd} = Enum.at(parts, 1)
    assert length(parts) == 2
  end

  test "should add a cent in the first part of $ 1 divided by 3", context do
    usd = context.usd

    {:ok, money} = Money.create(1, usd)

    parts = Money.divide(money, 3)

    assert {0, 34, ^usd} = Enum.at(parts, 0)
    assert {0, 33, ^usd} = Enum.at(parts, 1)
    assert {0, 33, ^usd} = Enum.at(parts, 2)
    assert length(parts) == 3
  end

  test "should distribute 2 cents in the firsts parts of $2.33 divided by 5", context do
    usd = context.usd

    {:ok, money} = Money.create(2.33, usd)

    parts = Money.divide(money, 5)

    assert {0, 47, ^usd} = Enum.at(parts, 0)
    assert {0, 47, ^usd} = Enum.at(parts, 1)
    assert {0, 47, ^usd} = Enum.at(parts, 2)
    assert {0, 46, ^usd} = Enum.at(parts, 3)
    assert {0, 46, ^usd} = Enum.at(parts, 4)
    assert {:ok, ^money} = Enum.reduce(parts, Money.create(0, usd), fn(x, {:ok, acc}) -> Money.sum(x, acc) end)
    assert length(parts) == 5
  end

  test "should return true on is_negative for negative money", context do
    usd = context.usd

    {:ok, money} = Money.create(-1, usd)

    assert Money.is_negative(money)
  end

  test "should return false on is_negative for zero money", context do
    usd = context.usd

    {:ok, money} = Money.create(0, usd)

    assert !Money.is_negative(money)
  end

  test "should return false on is_negative for positive money", context do
    usd = context.usd

    {:ok, money} = Money.create(0, usd)

    assert !Money.is_negative(money)
  end

  test "should return true on is zero for zero money", context do
    usd = context.usd

    {:ok, zero} = Money.create(0, usd)

    assert Money.is_zero(zero)
  end

  test "should return currency on get_currency", context do
    usd = context.usd

    {:ok, zero} = Money.create(0, usd)

    assert usd == Money.get_currency(zero)
  end
end
