defmodule FinancialSystemDepositTest do
  use ExUnit.Case
  doctest FinancialSystem

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, usd} = Currency.create("USD", "840", 2, "$")

    {:ok, one_half_brl} = Money.create(1.50, brl)
    {:ok, one_half_usd} = Money.create(1.50, usd)

    {:ok, zero_brl} = Money.create(0, brl)
    {:ok, zero_usd} = Money.create(0, usd)

    system = FinancialSystem.create("system")
    {:ok, system, brl_account1} = FinancialSystem.add_account(system, "brl_acount1", zero_brl)
    {:ok, system, brl_account2} = FinancialSystem.add_account(system, "brl_account2", zero_brl)
    {:ok, system, usd_account} = FinancialSystem.add_account(system, "usd_acount", zero_usd)

    %{
      system: system,
      brl: brl,
      zero_brl: zero_brl,
      one_half_brl: one_half_brl,
      one_half_usd: one_half_usd,
      brl_account1: brl_account1,
      brl_account2: brl_account2,
      usd_account: usd_account
    }
  end

  test "should be able to deposit money into account with the same currency", %{
    system: system,
    one_half_brl: one_half_brl,
    brl_account1: brl_account1
  } do
    {:ok, system, transaction} = FinancialSystem.deposit(system, brl_account1, one_half_brl)

    {id, {from_account, from_money}, {to_account, to_money}} = transaction

    assert id == 1
    assert {2, "deposit BRL", _, _} = from_account
    assert from_money == Money.negative(one_half_brl)
    assert to_account == brl_account1
    assert to_money == one_half_brl
    assert List.last(system.transactions) == transaction
  end

  test "should calculate balance with no transactions", %{system: system, brl_account1: brl_account1, zero_brl: zero_brl} do
    assert {:ok, ^zero_brl} = FinancialSystem.balance(system, brl_account1)
  end

  test "should calculate balance after transactions", %{system: system, brl_account1: brl_account1, one_half_brl: one_half_brl, brl: brl} do
    {:ok, system, _} = FinancialSystem.deposit(system, brl_account1, one_half_brl)

    assert {:ok, ^one_half_brl} = FinancialSystem.balance(system, brl_account1)

    {:ok, system, _} = FinancialSystem.deposit(system, brl_account1, one_half_brl)
    
    {:ok, three_brl} = Money.create(3, brl)
    assert {:ok, ^three_brl} = FinancialSystem.balance(system, brl_account1)
  end

  test "should not deposit money with different currency from the account" do
    assert false
  end
end
