defmodule TransactionTest do
  use ExUnit.Case
  doctest Transaction

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, usd} = Currency.create("USD", "840", 2, "$")
    {:ok, one_brl} = Money.create(1, brl)
    {:ok, zero_brl} = Money.create(0, brl)
    {:ok, one_usd} = Money.create(1, usd)
    {:ok, acc1} = Account.create(1, "Bruce Wayne", zero_brl)
    {:ok, acc2} = Account.create(2, "Clark Kent", zero_brl)
    {:ok, acc3} = Account.create(3, "Frank Castle", one_usd)

    %{one_brl: one_brl, acc1: acc1, acc2: acc2, acc3: acc3, zero_brl: zero_brl, brl: brl, usd: usd, one_usd: one_usd}
  end

  test "should create a transaction and set debit and credit values of it", %{
    one_brl: one_brl,
    acc1: acc1,
    acc2: acc2
  } do
    transaction = Transaction.create(1, acc1, Money.negative(one_brl), acc2, one_brl)

    {:ok, {id, {from, debit}, {to, credit}}} = transaction

    assert id == 1
    assert from == acc1
    assert debit == Money.negative(one_brl)
    assert to == acc2
    assert credit == one_brl
  end

  test "money to create a transaction must be positive", %{
    one_brl: one_brl,
    acc1: acc1,
    acc2: acc2
  } do
    transaction = Transaction.create(1, acc1, one_brl, acc2, Money.negative(one_brl))

    assert {:error, "Debit in a transaction should be negative"} = transaction
  end


  test "money to create a transaction must be non zero", %{
    zero_brl: zero_brl,
    acc1: acc1,
    acc2: acc2
  } do
    transaction = Transaction.create(1, acc1, zero_brl, acc2, Money.negative(zero_brl))

    assert {:error, "Debit in a transaction should be negative"} = transaction
  end

  test "should be able to transact between different currencies", %{
    acc1: acc1,
    acc3: acc3,
    usd: usd,
    brl: brl
  } do
    {:ok, one_usd} = Money.create(1, usd)
    {:ok, minus_one_brl} = Money.create(-1, brl)

    assert {:ok, {1, {^acc1, ^minus_one_brl}, {^acc3, ^one_usd}}} = Transaction.create(1, acc1, minus_one_brl, acc3, one_usd)
  end

  test "should not create a transaction if money from account has not same currency as the account", %{
    acc1: acc1,
    acc3: acc3,
    one_usd: one_usd
  } do
    assert {:error, "Account 1 does not operate with USD"} = Transaction.create(1, acc1, one_usd, acc3, one_usd)
  end

  test "should not create a transaction if money to account has not same currency as the account", %{
    acc1: acc1,
    acc3: acc3,
    one_brl: one_brl
  } do
    assert {:error, "Account 3 does not operate with BRL"} = Transaction.create(1, acc1, one_brl, acc3, one_brl)
  end

  test "transactions with same currency should have same absolute value, only different signals", %{
    acc1: acc1,
    acc2: acc2,
    one_brl: one_brl,
    brl: brl
  } do
    {:ok, minus_one_fifty_brl} = Money.create(-1.5, brl)

    assert {:error, "Transactions from same currencies must have same values"} = Transaction.create(1, acc1, minus_one_fifty_brl, acc2, one_brl)
  end
end
