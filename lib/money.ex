defmodule Money do
  alias Currency

  def create(amount, currency) when is_integer(amount) do
    create(amount / 1, currency)
  end

  def create(amount, currency) when is_float(amount) do
    cond do
      currency == nil ->
        {:error, "Currency is not present"}

      true ->
        no_comma_amout = Float.round(amount * Currency.factor(currency))
        
        raw_integer(trunc(no_comma_amout), currency)
    end
  end

  def raw_integer(raw_integer, currency) when is_integer(raw_integer) do
    factor = Currency.factor(currency)

    integer = div(raw_integer, factor)
    exponent = rem(raw_integer, factor)

    {:ok, {integer, exponent, currency}}
  end

  def sum({integer1, exponent1, currency1}, {integer2, exponent2, currency2}) do
    if currency1 != currency2 do
      {:error, "You can only sum money from the same currency"}
    else
      factor = Currency.factor(currency1)

      amount1 = integer1 * factor + exponent1
      amount2 = integer2 * factor + exponent2

      sum = amount1 + amount2
      
      raw_integer(sum, currency1)
    end
  end

  def negative({integer, exponent, currency}) do
    {:ok, {-integer, -exponent, currency}}
  end

  def to_string({integer, exponent, currency}) do
    "#{currency.repr} #{integer}.#{abs(exponent)}"
  end

  
end
