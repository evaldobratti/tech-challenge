defmodule Money do
  alias Currency

  defstruct integer_amount: nil, exponent_amount: nil, currency: nil

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
         %Money{
           integer_amount: integer_amount,
           exponent_amount: exponent_amount,
           currency: currency
         }}
    end
  end

  def sum(arg1, arg2) do
    if arg1.currency != arg2.currency do
      {:error, "You can only sum money from the same currency"}
    else
      %{integer_amount: integer1, exponent_amount: exponent1, currency: currency} = arg1
      %{integer_amount: integer2, exponent_amount: exponent2} = arg2

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

      {:ok, %Money{integer_amount: integer, exponent_amount: exponent, currency: currency}}
    end
  end

  def negative(%Money{integer_amount: integer, exponent_amount: exponent, currency: currency}) do
    {:ok, %Money{integer_amount: -integer, exponent_amount: -exponent, currency: currency}}
  end
end
