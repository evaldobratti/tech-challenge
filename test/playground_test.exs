defmodule PlaygroundTest do
  use ExUnit.Case
  doctest FinancialSystem

  test "code in readme" do
    # Criando moeda
    {:ok, brl} = Currency.create("BRL", "986", 2, "R$")
    {:ok, usd} = Currency.create("USD", "840", 2, "$")
    {:ok, _} = Currency.create("JPY", "392", 0, "￥")

    # Criando dinheiro
    {:ok, zero_brl} = Money.create(0, brl)
    {:ok, zero_usd} = Money.create(0, usd)

    {:ok, ten_brl} = Money.create(10, brl)
    {:ok, ten_usd} = Money.create(10, usd)

    # Criando um sistema financeiro
    system = FinancialSystem.create("system")

    # Criando uma conta no sistema financeiro
    {:ok, system, acc_bruce} = FinancialSystem.add_account(system, "Bruce Wayne", ten_usd)
    {:ok, system, acc_clark} = FinancialSystem.add_account(system, "Clark Kent", zero_usd)
    {:ok, system, acc_frank} = FinancialSystem.add_account(system, "Frank Castle", zero_usd)

    # Depositando dinheiro
    assert FinancialSystem.balance(system, acc_bruce) == zero_usd

    {:ok, system, _} = FinancialSystem.deposit(system, acc_bruce, ten_usd)

    assert FinancialSystem.balance(system, acc_bruce) == ten_usd

    # Sacando dinheiro
    {:ok, five_usd} = Money.create(5, usd)

    assert FinancialSystem.balance(system, acc_bruce) == ten_usd
    {:ok, system, _} = FinancialSystem.withdraw(system, acc_bruce, five_usd)
    assert FinancialSystem.balance(system, acc_bruce) == five_usd

    assert FinancialSystem.balance(system, acc_clark) == zero_usd
    {:error, "No sufficient funds"} = FinancialSystem.withdraw(system, acc_clark, five_usd)
    assert FinancialSystem.balance(system, acc_clark) == zero_usd

    # Transferindo dinheiro
    assert FinancialSystem.balance(system, acc_bruce) == five_usd
    assert FinancialSystem.balance(system, acc_clark) == zero_usd

    {:ok, system, _} = FinancialSystem.transfer(system, acc_bruce, acc_clark, ten_usd)

    negative_five_usd = Money.negative(five_usd)

    assert FinancialSystem.balance(system, acc_bruce) == negative_five_usd
    assert FinancialSystem.balance(system, acc_clark) == ten_usd

    # Cambio
    ### Depósito
    assert FinancialSystem.balance(system, acc_bruce) == negative_five_usd

    {:ok, system, _} = FinancialSystem.deposit_exchange(system, acc_bruce, ten_brl, 0.5)

    assert FinancialSystem.balance(system, acc_bruce) == zero_usd

    ### Saque
    assert FinancialSystem.balance(system, acc_clark) == ten_usd

    {:ok, system, transaction} = FinancialSystem.withdraw_exchange(system, acc_clark, five_usd, brl, 3.33)

    assert FinancialSystem.balance(system, acc_clark) == five_usd

    {:ok,  after_exchange} = Money.create(16.65, brl)
    assert {_, _, {_, ^after_exchange}} = transaction

    ### Transferencia
    assert FinancialSystem.balance(system, acc_clark) == five_usd

    {:ok, one_usd} = Money.create(1, usd)

    {:ok, system, acc_evaldo} = FinancialSystem.add_account(system, "Evaldo Bratti", zero_brl)
    {:ok, system, _} = FinancialSystem.transfer_exchange(system, acc_clark, acc_evaldo, one_usd, 3.33)

    {:ok, four_usd} = Money.create(4, usd)
    {:ok, money_brl} = Money.create(3.33, brl)

    assert FinancialSystem.balance(system, acc_clark) == four_usd
    assert FinancialSystem.balance(system, acc_evaldo) == money_brl

    # Transferindo para múltiplas contas
    assert FinancialSystem.balance(system, acc_clark) == four_usd
    assert FinancialSystem.balance(system, acc_bruce) == zero_usd
    assert FinancialSystem.balance(system, acc_frank) == zero_usd

    {:ok, system, _} = FinancialSystem.transfer(system, acc_clark, [acc_bruce, acc_frank], four_usd)

    {:ok, two_usd} = Money.create(2, usd)

    assert FinancialSystem.balance(system, acc_clark) == zero_usd
    assert FinancialSystem.balance(system, acc_frank) == two_usd
    assert FinancialSystem.balance(system, acc_bruce) == two_usd

  end
end
