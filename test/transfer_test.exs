defmodule FinancialSystemTransferTest do
  use ExUnit.Case
  doctest FinancialSystem

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, usd} = Currency.create("USD", "840", 2, "$")

    {:ok, zero_brl} = Money.create(0, brl)
    {:ok, one_brl} = Money.create(1, brl)
    {:ok, one_half_brl} = Money.create(1.50, brl)

    system = FinancialSystem.create("system")

    %{
      system: system,
      usd: usd,
      brl: brl,
      zero_brl: zero_brl,
      one_brl: one_brl,
      one_half_brl: one_half_brl
    }
  end

  test "should transfer from and to accounts from the same currency", %{
    system: system,
    zero_brl: zero_brl,
    one_brl: one_brl
  } do
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", zero_brl)
    {:ok, system, to} = FinancialSystem.add_account(system, "Clark Kent", zero_brl)

    {:ok, system, _} = FinancialSystem.deposit(system, from, one_brl)

    {:ok, system, transaction} = FinancialSystem.transfer(system, from, to, one_brl)

    assert zero_brl == FinancialSystem.balance(system, from)
    assert one_brl == FinancialSystem.balance(system, to)

    minus_one_brl = Money.negative(one_brl)
    assert {2, {^from, ^minus_one_brl}, {^to, ^one_brl}} = transaction
  end

  test "should not transfer from account with no funds", %{
    system: system,
    zero_brl: zero_brl,
    one_brl: one_brl
  } do
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", zero_brl)
    {:ok, system, to} = FinancialSystem.add_account(system, "Clark Kent", zero_brl)

    assert {:error, "No sufficient funds"} = FinancialSystem.transfer(system, from, to, one_brl)
  end


  test "should transfer from account using its limit", %{
    system: system,
    zero_brl: zero_brl,
    one_brl: one_brl
  } do
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", one_brl)
    {:ok, system, to} = FinancialSystem.add_account(system, "Clark Kent", zero_brl)
    {:ok, system, transaction} = FinancialSystem.transfer(system, from, to, one_brl)

    minus_one_brl = Money.negative(one_brl)

    assert minus_one_brl == FinancialSystem.balance(system, from)
    assert one_brl == FinancialSystem.balance(system, to)
    assert {1, {^from, ^minus_one_brl}, {^to, ^one_brl}} = transaction
  end

  test "should transfer from one account to 3 accounts", %{
    system: system,
    brl: brl,
    zero_brl: zero_brl,
    one_brl: one_brl
  } do
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", zero_brl)
    {:ok, system, to1} = FinancialSystem.add_account(system, "Clark Kent", zero_brl)
    {:ok, system, to2} = FinancialSystem.add_account(system, "Frank Castle", zero_brl)
    {:ok, system, to3} = FinancialSystem.add_account(system, "James Howlett", zero_brl)

    {:ok, system, _} = FinancialSystem.deposit(system, from, one_brl)

    {:ok, system, transactions} = FinancialSystem.transfer(system, from, [to1, to2, to3], one_brl)

    {:ok, part1} = Money.create(0.34, brl)
    {:ok, part2} = Money.create(0.33, brl)

    assert {2, {^from, _}, {^to1, ^part1}} = Enum.at(transactions, 0)
    assert {3, {^from, _}, {^to2, ^part2}} = Enum.at(transactions, 1)
    assert {4, {^from, _}, {^to3, ^part2}} = Enum.at(transactions, 2)
    assert length(transactions) == 3

    assert FinancialSystem.balance(system, from) == zero_brl
    assert FinancialSystem.balance(system, to1) == part1
    assert FinancialSystem.balance(system, to2) == part2
    assert FinancialSystem.balance(system, to3) == part2
  end

end
