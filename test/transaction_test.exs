defmodule TransactionTest do
  use ExUnit.Case
  doctest Transaction

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, money} = Money.create(50, brl)
    {:ok, zero} = Money.create(0, brl)
    {:ok, acc1} = Account.create(1, "Bruce Wayne", zero)
    {:ok, acc2} = Account.create(2, "Clark Kent", zero)

    %{money: money, acc1: acc1, acc2: acc2, zero: zero}
  end

  test "should create a transaction and set debit and credit values of it", %{
    money: money,
    acc1: acc1,
    acc2: acc2
  } do
    transaction = Transaction.create(1, acc1, acc2, money)

    {:ok, {id, {from, debit}, {to, credit}}} = transaction

    assert id == 1
    assert from == acc1
    assert debit == Money.negative(money)
    assert to == acc2
    assert credit == money
  end

  test "money to create a transaction must be positive", %{
    money: money,
    acc1: acc1,
    acc2: acc2
  } do
    transaction = Transaction.create(1, acc1, acc2, Money.negative(money))

    assert {:error, "Money from a transaction must be positive"} = transaction
  end


  test "money to create a transaction must be non zero", %{
    zero: zero,
    acc1: acc1,
    acc2: acc2
  } do
    transaction = Transaction.create(1, acc1, acc2, Money.negative(zero))

    assert {:error, "Money from a transaction must be positive"} = transaction
  end
end
