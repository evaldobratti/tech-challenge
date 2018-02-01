defmodule FinancialSystemTest do
  use ExUnit.Case
  doctest FinancialSystem

  @tag :skip
  test "User should be able to transfer money to another account" do
    assert :false
  end

  @tag :skip
  test "User cannot transfer if not enough money available on the account" do
    assert :false
  end

  @tag :skip
  test "A transfer should be cancelled if an error occurs" do
    assert :false
  end

  @tag :skip
  test "A transfer can be splitted between 2 or more accounts" do
    assert :false
  end

  @tag :skip
  test "User should be able to exchange money between different currencies" do
    assert :false
  end

  @tag :skip
  test "Currencies should be in compliance with ISO 4217" do
    assert :false
  end
end
