defmodule FinancialSystemTest do
  use ExUnit.Case
  doctest FinancialSystem

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, usd} = Currency.create("USD", "840", 2, "$")

    {:ok, one_half_brl} = Money.create(1.50, brl)
    {:ok, one_half_usd} = Money.create(1.50, usd)

    {:ok, zero_brl} = Money.create(0, brl)
    {:ok, zero_usd} = Money.create(0, usd)

    %{
      brl: brl,
      usd: usd,
      one_half_brl: one_half_brl,
      one_half_usd: one_half_usd,
      zero_brl: zero_brl,
      zero_usd: zero_usd
    }
  end

  test "should create financial system with empty control structures" do
    assert %{:name => "Financial System", :accounts => [], :transactions => []} =
             FinancialSystem.create("Financial System")
  end

  test "should create control accounts for a new currency in the sytem", %{
    brl: brl,
    zero_brl: zero_brl
  } do
    system = FinancialSystem.create("system")

    system = FinancialSystem.create_currency_control_accounts(system, brl)

    accounts = system.accounts

    assert {1, "bank BRL", ^zero_brl, ^brl} = Enum.at(accounts, 0)
    assert {2, "deposit BRL", ^zero_brl, ^brl} = Enum.at(accounts, 1)
    assert {3, "withdrawal BRL", ^zero_brl, ^brl} = Enum.at(accounts, 2)
    assert length(accounts) == 3

    control_accounts_brl = Map.get(system, brl)
    assert control_accounts_brl == List.to_tuple(accounts)
  end

  test "should not add control accounts if the currency already has its ones", %{brl: brl} do
    system = FinancialSystem.create("system")

    system = FinancialSystem.create_currency_control_accounts(system, brl)
    repeated_brl = FinancialSystem.create_currency_control_accounts(system, brl)

    assert system == repeated_brl
  end

  test "should add new user account", %{brl: brl, zero_brl: zero_brl} do
    {:ok, _, new_account} =
      FinancialSystem.create("system")
      |> FinancialSystem.create_currency_control_accounts(brl)
      |> FinancialSystem.add_account("Bruce Wayne", zero_brl)

    assert {4, "Bruce Wayne", ^zero_brl, ^brl} = new_account
  end

  test "should automatically create control accounts when new account limit currency is added", %{
    brl: brl,
    zero_brl: zero_brl,
    usd: usd,
    zero_usd: zero_usd
  } do
    system =
      with system <- FinancialSystem.create("system"),
           {:ok, system, _} <- FinancialSystem.add_account(system, "Bruce Wayne", zero_brl),
           {:ok, system, _} <- FinancialSystem.add_account(system, "Clark Kent", zero_usd) do
        system
      end

    accounts = system.accounts

    assert {1, "bank BRL", ^zero_brl, ^brl} = Enum.at(accounts, 0)
    assert {2, "deposit BRL", ^zero_brl, ^brl} = Enum.at(accounts, 1)
    assert {3, "withdrawal BRL", ^zero_brl, ^brl} = Enum.at(accounts, 2)
    assert {4, "Bruce Wayne", ^zero_brl, ^brl} = Enum.at(accounts, 3)

    assert {5, "bank USD", ^zero_usd, ^usd} = Enum.at(accounts, 4)
    assert {6, "deposit USD", ^zero_usd, ^usd} = Enum.at(accounts, 5)
    assert {7, "withdrawal USD", ^zero_usd, ^usd} = Enum.at(accounts, 6)
    assert {8, "Clark Kent", ^zero_usd, ^usd} = Enum.at(accounts, 7)
  end

  test "User should be able to transfer money to another account", %{usd: usd, zero_usd: zero_usd} do
    system = FinancialSystem.create("system")

    {:ok, limit} = Money.create(10, usd)
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", limit)
    {:ok, system, to} = FinancialSystem.add_account(system, "Clark Kent", zero_usd)

    {:ok, transfer_money} = Money.create(3.44, usd)
    {:ok, system, _ } = FinancialSystem.transfer(system, from, to, transfer_money)

    assert {:ok, FinancialSystem.balance(system, from)} == Money.create(-3.44, usd)
    assert {:ok, FinancialSystem.balance(system, to)} == Money.create(3.44, usd)
  end

  test "User cannot transfer if not enough money available on the account", %{usd: usd, zero_usd: zero_usd} do
    system = FinancialSystem.create("system")

    {:ok, ten_usd} = Money.create(10, usd)
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", zero_usd)
    {:ok, system, to} = FinancialSystem.add_account(system, "Clark Kent", zero_usd)

    assert {:error, "No sufficient funds"} = FinancialSystem.transfer(system, from, to, ten_usd)
  end

  test "A transfer should be cancelled if an error occurs", %{usd: usd, zero_usd: zero_usd} do
    system = FinancialSystem.create("system")

    {:ok, ten_usd} = Money.create(10, usd)
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", zero_usd)

    assert {:error, "Transfer should have different accounts"} = FinancialSystem.transfer(system, from, from, ten_usd)
  end

  test "A transfer can be splitted between 2 or more accounts", %{usd: usd, zero_usd: zero_usd} do
    system = FinancialSystem.create("system")

    {:ok, ten_usd} = Money.create(10, usd)
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", ten_usd)
    {:ok, system, to1} = FinancialSystem.add_account(system, "Clark Kent", zero_usd)
    {:ok, system, to2} = FinancialSystem.add_account(system, "Frank Castle", zero_usd)

    {:ok, to_transfer} = Money.create(2.33, usd)

    {:ok, system, _ } = FinancialSystem.transfer(system, from, [to1, to2], to_transfer)

    assert {:ok, FinancialSystem.balance(system, from)} == Money.create(-2.33, usd)
    assert {:ok, FinancialSystem.balance(system, to1)} == Money.create(1.17, usd)
    assert {:ok, FinancialSystem.balance(system, to2)} == Money.create(1.16, usd)
  end

  test "User should be able to exchange money between different currencies", %{brl: brl, usd: usd} do
    system = FinancialSystem.create("system")

    {:ok, ten_usd} = Money.create(10, usd)
    {:ok, system, from} = FinancialSystem.add_account(system, "Bruce Wayne", ten_usd)

    {:ok, money} = Money.create(5, usd)

    {:ok, system, transaction} = FinancialSystem.withdraw_exchange(system, from, money, brl, 3.42)

    negative_money = Money.negative(money)
    {_, {^from, ^negative_money}, {_, withdraw}} = transaction

    assert {:ok, FinancialSystem.balance(system, from)} == Money.create(-5, usd)
    assert {:ok, ^withdraw} = Money.create(17.10, brl)
  end

  test "Currencies should be in compliance with ISO 4217", %{usd: usd, brl: brl} do
    assert %Currency{code_alpha: "USD", code_number: "840", exponent: 2, repr: "$"} == usd
    assert %Currency{code_alpha: "BRL", code_number: "986", exponent: 2, repr: "R$"} == brl

    {:ok, yen} = Currency.create("JPY", "392", 0, "￥")

    {:ok, money_usd} = Money.create(1.22, usd)
    {:ok, money_brl} = Money.create(1.22, brl)
    {:ok, money_yen} = Money.create(1.22333, yen)

    assert {1, 22, ^usd} = money_usd
    assert {1, 22, ^brl} = money_brl
    assert {1, 0, ^yen} = money_yen

    assert Money.to_string(money_usd) == "$ 1.22"
    assert Money.to_string(money_brl) == "R$ 1.22"
    assert Money.to_string(money_yen) == "￥ 1"
  end
end


