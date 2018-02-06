defmodule AccountsManagementTest do
  use ExUnit.Case
  doctest AccountsManagement

  setup do
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, zero} = Money.create(0, brl)
    {:ok, fifty} = Money.create(50, brl)
    %{zero: zero, brl: brl, fifty: fifty}
  end

  test "should add new account with proper identifier", %{zero: zero, brl: brl} do
    {:ok, accounts} = AccountsManagement.add([], "Bruce Wayne", zero)

    assert {1, "Bruce Wayne", ^zero, ^brl} = Enum.at(accounts, 0)
    assert length(accounts) == 1
  end

  test "should carry error from Account.create", %{fifty: fifty} do
    result = AccountsManagement.add([], "Evaldo Bratti", Money.negative(fifty))

    assert {:error, "Limit should not be negative"} = result
  end

  test "should add new account when there is already accounts", %{zero: zero, brl: brl} do
    {:ok, accounts} = AccountsManagement.add([], "Bruce Wayne", zero)
    {:ok, accounts} = AccountsManagement.add(accounts, "Clark Kent", zero)

    assert {1, "Bruce Wayne", ^zero, ^brl} = Enum.at(accounts, 0)
    assert {2, "Clark Kent", ^zero, ^brl} = Enum.at(accounts, 1)
    assert length(accounts) == 2
  end

  test "should not add account with already existing account with that name", %{zero: zero} do
    {:ok, accounts} = AccountsManagement.add([], "Bruce Wayne", zero)
    result = AccountsManagement.add(accounts, "Bruce Wayne", zero)

    assert {:error, "Already registered account"} = result
  end
end