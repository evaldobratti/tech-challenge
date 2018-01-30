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
        integer_amount = trunc(amount)
        difference = amount - integer_amount
        exponent_amount = Float.round(difference * :math.pow(10, currency.exponent))

        {:ok,
         {
           integer_amount,
           exponent_amount,
           currency
         }}
    end
  end

  def sum(arg1, arg2) do
    if elem(arg1, 2) != elem(arg2, 2) do
      {:error, "You can only sum money from the same currency"}
    else
      {integer1, exponent1, currency} = arg1
      {integer2, exponent2, _} = arg2

      integer = integer1 + integer2
      exponent = exponent1 + exponent2
      max_exponent = :math.pow(10, currency.exponent)
      min_exponent = -max_exponent

      {integer, exponent} =
        cond do
          exponent >= max_exponent -> {integer + 1, exponent - max_exponent}
          integer > 0 && exponent < 0 -> {integer - 1, exponent + max_exponent}
          exponent <= min_exponent -> {integer - 1, exponent + max_exponent}
          true -> {integer, exponent}
        end

      {:ok, {integer, exponent, currency}}
    end
  end

  def negative({integer, exponent, currency}) do
    {:ok, {-integer, -exponent, currency}}
  end
end
