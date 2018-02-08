defmodule Money do
  alias Currency

  @significant_floating_point 5

  def create(amount, currency) when is_integer(amount) do
    create(amount / 1, currency)
  end

  def create(amount, currency) when is_float(amount) do
    cond do
      currency == nil ->
        {:error, "Currency is not present"}

      true ->
        no_comma_amout = Float.round(amount * Currency.factor(currency))

        {:ok, raw_integer(trunc(no_comma_amout), currency)}
    end
  end

  defp raw_integer(raw_integer, currency) when is_integer(raw_integer) do
    factor = Currency.factor(currency)

    integer = div(raw_integer, factor)
    exponent = rem(raw_integer, factor)

    {integer, exponent, currency}
  end

  defp to_raw_integer({integer, exponent, currency}) do
    factor = Currency.factor(currency)
    integer * factor + exponent
  end

  def sum({_, _, currency1} = money1, {_, _, currency2} = money2) do
    if currency1 != currency2 do
      {:error, "You can only sum money from the same currency"}
    else
      amount1 = to_raw_integer(money1)
      amount2 = to_raw_integer(money2)

      sum = amount1 + amount2

      {:ok, raw_integer(sum, currency1)}
    end
  end

  def negative({integer, exponent, currency}) do
    {-integer, -exponent, currency}
  end

  def to_string({integer, exponent, currency}) do
    "#{currency.repr} #{integer}.#{abs(exponent)}"
  end

  def exchange({_, _, currency_from} = money_from, currency_to, rate) do
    cond do
      currency_from == currency_to ->
        cond do
          rate != 1 ->
            {:error, "Exchanging from to the same currency should have 1 as rate"}

          true ->
            {:ok, money_from, {0, currency_from}}
        end

      true ->
        amount = to_raw_integer(money_from)

        exchanged_amount = amount * rate
        significant = trunc(exchanged_amount)
        insignificant = exchanged_amount - significant

        leftover =
          (insignificant * :math.pow(10, @significant_floating_point))
          |> Float.round()
          |> trunc()

        {:ok, raw_integer(significant, currency_to), {leftover, currency_to}}
    end
  end

  def divide({_, _, currency} = money, divisor) when is_integer(divisor) and divisor > 1 do
    amount = to_raw_integer(money)

    divided = div(amount, divisor)

    difference = amount - (divided * divisor)
    
    parts = Enum.map(1..divisor, fn(_)-> raw_integer(divided, currency) end)

    distributed_parts = distribute(difference, parts)

    {:ok,  distributed_parts}
  end

  defp distribute(0, list) do 
    list
  end

  defp distribute(difference, [ {_, _, currency} = part | others ]) do
    [raw_integer(to_raw_integer(part) + 1, currency)] ++ distribute(difference - 1, others)
  end

  def is_negative(money) do
    to_raw_integer(money) < 0
  end

  def is_zero(money) do
    to_raw_integer(money) == 0
  end

  def get_currency(money) do
    {_, _, currency} = money
    currency
  end
end
