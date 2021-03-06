defmodule FinancialSystemWithdrawalTest do
  use ExUnit.Case
  doctest FinancialSystem

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, usd} = Currency.create("USD", "840", 2, "$")

    {:ok, one_brl} = Money.create(1, brl)
    {:ok, one_usd} = Money.create(1, usd)
    {:ok, one_half_brl} = Money.create(1.50, brl)
    {:ok, zero_brl} = Money.create(0, brl)

    system = FinancialSystem.create("system")
    {:ok, system, no_limit_account} = FinancialSystem.add_account(system, "no limit", zero_brl)

    {:ok, system, one_brl_limit_account} =
      FinancialSystem.add_account(system, "one brl limit", one_brl)

    %{
      system: system,
      usd: usd,
      brl: brl,
      zero_brl: zero_brl,
      one_brl: one_brl,
      one_half_brl: one_half_brl,
      one_usd: one_usd,
      no_limit_account: no_limit_account,
      one_brl_limit_account: one_brl_limit_account
    }
  end

  test "should withdraw from account with no limit but with a deposit", %{
    system: system,
    zero_brl: zero_brl,
    one_brl: one_brl,
    no_limit_account: no_limit_account
  } do
    {:ok, system, _} = FinancialSystem.deposit(system, no_limit_account, one_brl)

    assert one_brl == FinancialSystem.balance(system, no_limit_account)

    {:ok, system, transaction} = FinancialSystem.withdraw(system, no_limit_account, one_brl)

    {id, {from_account, from_money}, {to_account, to_money}} = transaction

    assert id == 2
    assert from_account == no_limit_account
    assert from_money == Money.negative(one_brl)
    assert {3, "withdrawal BRL", _, _} = to_account
    assert to_money == one_brl
    assert List.last(system.transactions) == transaction

    assert zero_brl == FinancialSystem.balance(system, no_limit_account)
  end

  test "should withdraw from account with limit", %{
    system: system,
    one_brl: one_brl,
    one_brl_limit_account: one_brl_limit_account
  } do
    {:ok, system, transaction} = FinancialSystem.withdraw(system, one_brl_limit_account, one_brl)

    {id, {from_account, from_money}, {to_account, to_money}} = transaction

    assert id == 1
    assert from_account == one_brl_limit_account
    assert from_money == Money.negative(one_brl)
    assert {3, "withdrawal BRL", _, _} = to_account
    assert to_money == one_brl
    assert List.last(system.transactions) == transaction

    assert Money.negative(one_brl) == FinancialSystem.balance(system, one_brl_limit_account)
  end

  test "should not withdraw from account with no limit and no funds", %{
    system: system,
    one_brl: one_brl,
    no_limit_account: no_limit_account
  } do
    assert {:error, "No sufficient funds"} = FinancialSystem.withdraw(system, no_limit_account, one_brl)
  end

  test "should not withdraw from account with limit and but no funds", %{
    system: system,
    one_half_brl: one_half_brl,
    one_brl_limit_account: one_brl_limit_account
  } do
    assert {:error, "No sufficient funds"} = FinancialSystem.withdraw(system, one_brl_limit_account, one_half_brl)
  end

  test "should not withdraw money with different currency from the account", %{
    system: system,
    no_limit_account: no_limit_account,
    one_usd: one_usd
  } do
    assert {:error, "Account 4 does not operate with USD"} = FinancialSystem.withdraw(system, no_limit_account, one_usd)
  end

  test "should not withdraw from unregistered account", %{system: system, zero_brl: zero_brl} do
    {:ok, unregistered_account} = Account.create(44, "Joker", zero_brl)

    assert {:error, "Not registered account"} = FinancialSystem.withdraw(system, unregistered_account, zero_brl)
  end

  test "should not withdraw zero money", %{
    system: system,
    one_brl_limit_account: one_brl_limit_account,
    zero_brl: zero_brl
  } do
    assert {:error, "Debit in a transaction should be negative"} = FinancialSystem.withdraw(system, one_brl_limit_account, zero_brl)
  end

  test "should withdraw 1 BRL in USD", %{
    system: system,
    usd: usd,
    one_brl: one_brl,
    one_brl_limit_account: one_brl_limit_account
  } do
    {:ok, system, transaction} = FinancialSystem.withdraw_exchange(system, one_brl_limit_account, one_brl, usd, 0.33)

    {:ok, exchanged} = Money.create(0.33, usd)
    withdraw = Money.negative(one_brl)

    assert {1, {^one_brl_limit_account, ^withdraw}, {_, ^exchanged}} = transaction
    assert FinancialSystem.balance(system, one_brl_limit_account) == Money.negative(one_brl)
  end

  test "should not withdraw from private account", %{system: system, one_brl: one_brl} do
    private_account = Enum.at(system.accounts, 0)

    assert {:error, "You cannot use private accounts"} = FinancialSystem.withdraw(system, private_account, one_brl)
  end

end
