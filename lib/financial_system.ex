defmodule FinancialSystem do
  @moduledoc """
  Documentation for FinancialSystem.
  """

  alias Transaction

  def create(name) do
    %{name: name, accounts: [], transactions: [], private_accounts: []}
  end

  def create_currency_control_accounts(system, currency) do
    %{code_alpha: code_alpha} = currency

    with {:ok, zero} <- Money.create(0, currency),
         {:ok, accounts} <- AccountsManagement.add(system.accounts, "bank " <> code_alpha, zero),
         {:ok, accounts} <- AccountsManagement.add(accounts, "deposit " <> code_alpha, zero),
         {:ok, accounts} <- AccountsManagement.add(accounts, "withdrawal " <> code_alpha, zero) do
      currency_accounts = Enum.take(accounts, -3)
      private_accounts = system.private_accounts ++ currency_accounts

      %{system | :accounts => accounts, :private_accounts => private_accounts}
      |> Map.put(currency, List.to_tuple(currency_accounts))
    else
      {:error, "Already registered account"} -> system
    end
  end

  def add_account(system, account_name, limit) do
    {_, _, currency} = limit

    with system <- create_currency_control_accounts(system, currency),
         {:ok, accounts} <- AccountsManagement.add(system.accounts, account_name, limit) do
      {:ok, %{system | :accounts => accounts}, List.last(accounts)}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def deposit(system, account, money) do
    case Transaction.is_compatible_currencies(account, money) do
      {:ok} -> 
        deposit_account = get_deposit_account(system, Account.get_native_currency(account))
        transfer(system, deposit_account, account, money, false)
      {:error, msg} -> {:error, msg}
    end
  end

  def withdraw(system, account, money) do
    case Transaction.is_compatible_currencies(account, money) do
      {:ok} -> 
        withdraw_account = get_withdraw_account(system, Account.get_native_currency(account))
        transfer(system, account, withdraw_account, money, true)
      {:error, msg} -> {:error, msg}
    end
  end

  def transfer(system, from, to, money) when not is_list(to) do
    case valid_transfer(system, from, to) do
      {:ok} -> transfer(system, from, to, money, true)
      {:error, msg} -> {:error, msg}
    end
  end

  def transfer(system, from, list_to, money) when is_list(list_to) do
    parts = Money.divide(money, length(list_to))

    case transfer_parts(system, from, list_to, parts) do
      {:ok, system, _} -> {:ok, system, Enum.take(system.transactions, -length(list_to))}
      {:error, message} -> {:error, message}
    end
  end

  defp transfer_parts(system, from, [to | others_to], [part | others_parts]) do
    case valid_transfer(system, from, to) do
      {:ok} ->
        case transfer(system, from, to, part, true) do
          {:ok, system, transaction} ->
            if length(others_to) > 0 do
              transfer_parts(system, from, others_to, others_parts)
            else
              {:ok, system, transaction}
            end
          {:error, msg} ->
            {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  def valid_transfer(system, from, to) do
    cond do
      is_private_account(system, from) -> {:error, "You cannot transfer using private accounts"}
      is_private_account(system, to) -> {:error, "You cannot transfer using private accounts"}
      true -> {:ok}
    end
  end

  defp is_private_account(system, account) do
    Enum.member?(system.private_accounts, account)
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
            account_limit = Account.get_limit(from)

            funds = balance(system, from)
            {:ok, funds} = Money.sum(funds, account_limit)
            {:ok, funds} = Money.sum(funds, from_money)
            Money.is_positive(funds) or Money.is_zero(funds)
          else
            true
          end

        cond do
          !has_funds ->
            {:error, "No sufficient funds"}

          true ->
            case Transaction.create(length(system.transactions) + 1, from, from_money, to, to_money) do
              {:ok, transaction} ->
                {:ok, %{system | transactions: system.transactions ++ [transaction]}, transaction}

              {:error, msg} ->
                {:error, msg}
            end
        end
    end
  end

  defp get_deposit_account(system, currency) do
    {_, deposit, _} = Map.get(system, currency)
    deposit
  end

  defp get_withdraw_account(system, currency) do
    {_, _, withdraw} = Map.get(system, currency)
    withdraw
  end

  def is_registered_account(system, account) do
    Enum.member?(system.accounts, account)
  end

  def balance(system, account) do
    currency = Account.get_native_currency(account)
    zero = Money.create(0, currency)

    credits =
      system
      |> transactions_envolving(account)
      |> Enum.map(fn t ->
        case t do
          {_, {^account, debit}, _} -> debit
          {_, _, {^account, credit}} -> credit
        end
      end)

    # TODO put reduce/sum in money module
    {:ok, balance} = Enum.reduce(credits, zero, fn x, {:ok, acc} -> Money.sum(x, acc) end)
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
