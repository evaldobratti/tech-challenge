defmodule FinancialSystem do
  @moduledoc """
  Documentation for FinancialSystem.
  """

  alias Transaction
  import AccountsManagement

  def create(name) do
    %{name: name, accounts: [], transactions: [], private_accounts: []}
  end

  def create_currency_control_accounts(system, currency) do
    %{code_alpha: code_alpha} = currency

    if Map.get(system, currency) == nil do
      with {:ok, zero} <- Money.create(0, currency),
          {:ok, accounts} <- add(system.accounts, "bank " <> code_alpha, zero),
          {:ok, accounts} <- add(accounts, "deposit " <> code_alpha, zero),
          {:ok, accounts} <- add(accounts, "withdrawal " <> code_alpha, zero) do
        currency_accounts = Enum.take(accounts, -3)
        private_accounts = system.private_accounts ++ currency_accounts

        %{system |
          :accounts => accounts,
          :private_accounts => private_accounts}
        |> Map.put(currency, List.to_tuple(currency_accounts))
      else
        {:error, "Already registered account"} -> system
      end
    else
      system
    end
  end

  def add_account(system, account_name, limit) do
    {_, _, currency} = limit

    with system <- create_currency_control_accounts(system, currency),
         {:ok, accounts} <- add(system.accounts, account_name, limit) do
      {:ok, %{system | :accounts => accounts}, List.last(accounts)}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def deposit(system, account, money) do
    case Transaction.is_compatible_currencies(account, money) do
      {:ok} -> deposit_exchange(system, account, money, 1)
      {:error, msg} -> {:error, msg}
    end
  end

  def withdraw(system, account, money) do
    case Transaction.is_compatible_currencies(account, money) do
      {:ok} ->
        withdraw_exchange(system, account, money, Money.get_currency(money), 1)
      {:error, msg} -> {:error, msg}
    end
  end

  def transfer(system, from, to, money) when not is_list(to) do
    with {:ok} <- valid_transfer(system, from, to),
      {:ok} <- Transaction.is_compatible_currencies(from, money),
      {:ok} <- Transaction.is_compatible_currencies(to, money) do
      transfer(system, from, to, money, true)
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def transfer(system, from, list_to, money) when is_list(list_to) do
    n = length(list_to)
    parts = Money.divide(money, n)

    case transfer_parts(system, from, list_to, parts) do
      {:ok, system, _} -> {:ok, system, Enum.take(system.transactions, -n)}
      {:error, message} -> {:error, message}
    end
  end

  def deposit_exchange(system, account, money, rate) do
    account_currency = Account.get_native_currency(account)
    money_currency = Money.get_currency(money)
    debit = Money.negative(money)

    {:ok, exchanged, _} = Money.exchange(money, account_currency, rate)
    {system, deposit_account} = get_deposit_account(system, money_currency)

    transfer(system, deposit_account, debit, account, exchanged, false)
  end

  def withdraw_exchange(system, account, money, currency, rate) do
    debit = Money.negative(money)

    case is_private_account(system, account) do
      {:ok} ->
        {:ok, exchanged, _} = Money.exchange(money, currency, rate)
        {system, withdraw_account} = get_withdraw_account(system, currency)
        transfer(system, account, debit, withdraw_account, exchanged, true)
      {:error, msg} -> {:error, msg}
    end
  end

  def transfer_exchange(system, from, to, money, rate) do
    to_currency = Account.get_native_currency(to)
    {:ok, exchanged, _} = Money.exchange(money, to_currency, rate)

    with {:ok} <- valid_transfer(system, from, to),
      {:ok} <- Transaction.is_compatible_currencies(from, money),
      {:ok} <- Transaction.is_compatible_currencies(to, exchanged) do
      transfer(system, from, Money.negative(money), to, exchanged, true)
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp transfer_parts(system, from, [to | others_to], [part | others_parts]) when length(others_to) >= 1 do
    case valid_transfer(system, from, to) do
      {:ok} ->
        case transfer(system, from, to, part, true) do
          {:ok, system, _} -> transfer_parts(system, from, others_to, others_parts)
          {:error, msg} -> {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  defp transfer_parts(system, from, [to], [part]) do
    case valid_transfer(system, from, to) do
      {:ok} -> transfer(system, from, to, part, true)
      {:error, msg} -> {:error, msg}
    end
  end

  def valid_transfer(system, from, to) do
    with {:ok} <- is_private_account(system, from),
      {:ok} <- is_private_account(system, to) do
      {:ok}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp is_private_account(system, account) do
    if Enum.member?(system.private_accounts, account) do
      {:error, "You cannot use private accounts"}
    else
      {:ok}
    end
  end

  defp transfer(system, from, to, money, check_funds) do
    transfer(system, from, Money.negative(money), to, money, check_funds)
  end

  defp transfer(system, from, from_money, to, to_money, check_funds) do
    cond do
      !is_registered_account(system, from) ->
        {:error, "Not registered account"}

      !is_registered_account(system, to) ->
        {:error, "Not registered account"}

      true ->
        has_funds =
          if check_funds do
            has_enough_funds(system, from, from_money)
          else
            true
          end

        if !has_funds do
          {:error, "No sufficient funds"}
        else
          id = length(system.transactions) + 1
          case Transaction.create(id, from, from_money, to, to_money) do
            {:ok, transaction} ->
              transactions = system.transactions ++ [transaction]
              {:ok, %{system | transactions: transactions}, transaction}

            {:error, msg} ->
              {:error, msg}
          end
        end
    end
  end

  defp has_enough_funds(system, account, money) do
    account_limit = Account.get_limit(account)

    funds = balance(system, account)
    {:ok, funds} = Money.sum(funds, account_limit)
    {:ok, funds} = Money.sum(funds, money)
    Money.is_positive(funds) or Money.is_zero(funds)
  end

  defp get_deposit_account(system, currency) do
    system = create_currency_control_accounts(system, currency)
    {_, deposit, _} = Map.get(system, currency)
    {system, deposit}
  end

  defp get_withdraw_account(system, currency) do
    system = create_currency_control_accounts(system, currency)
    {_, _, withdraw} = Map.get(system, currency)
    {system, withdraw}
  end

  def is_registered_account(system, account) do
    Enum.member?(system.accounts, account)
  end

  def balance(system, account) do
    currency = Account.get_native_currency(account)

    credits =
      system
      |> transactions_envolving(account)
      |> Enum.map(fn t ->
        case t do
          {_, {^account, debit}, _} -> debit
          {_, _, {^account, credit}} -> credit
        end
      end)

    {:ok, balance} = Money.sum_parts(currency, credits)
    balance
  end

  def transactions_envolving(system, account) do
    Enum.filter(system.transactions, fn t ->
      case t do
        {_, {^account, _}, {_, _}} -> true
        {_, {_, _}, {^account, _}} -> true
        _ -> false
      end
    end)
  end
end
