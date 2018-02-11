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

    {:ok, bigger_part} = Money.create(0.34, brl)
    {:ok, smaller_part} = Money.create(0.33, brl)

    assert {2, {^from, _}, {^to1, ^bigger_part}} = Enum.at(transactions, 0)
    assert {3, {^from, _}, {^to2, ^smaller_part}} = Enum.at(transactions, 1)
    assert {4, {^from, _}, {^to3, ^smaller_part}} = Enum.at(transactions, 2)
    assert length(transactions) == 3

    assert FinancialSystem.balance(system, from) == zero_brl
    assert FinancialSystem.balance(system, to1) == bigger_part
    assert FinancialSystem.balance(system, to2) == smaller_part
    assert FinancialSystem.balance(system, to3) == smaller_part
  end

  test "should not transfer from private accounts", %{
    system: system,
    one_brl: one_brl
  } do
    {:ok, system, to} = FinancialSystem.add_account(system, "Bruce Wayne", one_brl)
    
    deposit_hacking = Enum.at(system.accounts, 1)

    assert elem(deposit_hacking, 1) == "deposit BRL"

    assert {:error, "You cannot transfer using private accounts"} = FinancialSystem.transfer(system, deposit_hacking, to, one_brl)
  end

  test "should not transfer to private accounts", %{
    system: system,
    one_brl: one_brl
  } do
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", one_brl)
    
    withdraw_hacking = Enum.at(system.accounts, 2)

    assert elem(withdraw_hacking, 1) == "withdrawal BRL"

    assert {:error, "You cannot transfer using private accounts"} = FinancialSystem.transfer(system, from, withdraw_hacking, one_brl)
  end


  test "should not transfer from one account to N others when there is no sufficient funds", %{
    system: system,
    brl: brl,
    zero_brl: zero_brl,
    one_brl: one_brl
  } do
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", zero_brl)
    {:ok, system, to1} = FinancialSystem.add_account(system, "Clark Kent", zero_brl)
    {:ok, system, to2} = FinancialSystem.add_account(system, "Frank Castle", zero_brl)

    {:ok, system, _} = FinancialSystem.deposit(system, from, one_brl)

    {:ok, one_one_cent_brl} = Money.create(1.01, brl)

    assert {:error, "No sufficient funds"} == FinancialSystem.transfer(system, from, [to1, to2], one_one_cent_brl)
  end
end
