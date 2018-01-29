defmodule MoneyTest do
  use ExUnit.Case
  doctest Money

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2)
    {:ok, usd} = Currency.create("USD", "840", 2)
    %{brl: brl, usd: usd}
  end

  test "should create one BRL", context do 
    {:ok, money} = Money.create(1, context.brl)

    assert money.integer_amount == 1
    assert money.exponent_amount == 0
    assert money.currency == context.brl
  end

  test "should create floating point BRL", context do
    {:ok, money} = Money.create(1.39, context.brl)

    assert money.integer_amount == 1
    assert money.exponent_amount == 39
    assert money.currency == context.brl
  end

  test "should not create money without currency" do
    {:error, message} = Money.create(1, nil)

    assert message == "Currency is not present"
  end

  test "should create negative money", context do
    {:ok, money} = Money.create(-1.42, context.brl)

    assert money.integer_amount == -1
    assert money.exponent_amount == -42
    assert money.currency == context.brl
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

    assert sum.integer_amount == 2
    assert sum.exponent_amount == 0
    assert sum.currency == context.brl
  end

  test "should sum exponent amount from same currencies", context do
    {:ok, fourtyCents} = Money.create(0.40, context.brl)
    
    {:ok, sum} = Money.sum(fourtyCents, fourtyCents)

    assert sum.integer_amount == 0
    assert sum.exponent_amount == 80
    assert sum.currency == context.brl
  end

  test "should sum exponent amount and transfer it to integer part when it surpasses exponent from the currency", context do
    {:ok, sixtyCents} = Money.create(0.60, context.brl)

    {:ok, sum} = Money.sum(sixtyCents, sixtyCents)

    assert sum.integer_amount == 1
    assert sum.exponent_amount == 20
    assert sum.currency == context.brl
  end

  test "should sum integer from one and exponent from another", context do
    {:ok, oneReal} = Money.create(1, context.brl)
    {:ok, sixtyCents} = Money.create(0.60, context.brl)

    {:ok, sum} = Money.sum(oneReal, sixtyCents)

    assert sum.integer_amount == 1
    assert sum.exponent_amount == 60
    assert sum.currency == context.brl
  end

  test "should change signal on negative", context do
    {:ok, money} = Money.create(1.50, context.brl)

    {:ok, negative} = Money.negative(money)

    assert negative.integer_amount == -1
    assert negative.exponent_amount == -50
    assert negative.currency == context.brl
  end

  test "should sum positive and negative moneys", context do
    {:ok, fiveReais} = Money.create(5, context.brl)
    {:ok, threeHalfReais} = Money.create(-3.5, context.brl)

    {:ok, sum} = Money.sum(fiveReais, threeHalfReais)

    assert sum.integer_amount == 1
    assert sum.exponent_amount == 50
    assert sum.currency == context.brl
  end

  test "should sum positive exponent with negative exponent", context do
    {:ok, positiveExponent} = Money.create(0.23, context.brl)
    {:ok, negativeExponent} = Money.create(-0.47, context.brl)

    {:ok, sum} = Money.sum(positiveExponent, negativeExponent)

    assert sum.integer_amount == 0
    assert sum.exponent_amount == -24
    assert sum.currency == context.brl
  end

  test "should sum negative moneys", context do 
    {:ok, minusOneHalfReais} = Money.create(-1.54, context.brl)

    {:ok, sum} = Money.sum(minusOneHalfReais, minusOneHalfReais)

    assert sum.integer_amount == -3
    assert sum.exponent_amount == -8
    assert sum.currency == context.brl
  end

end  