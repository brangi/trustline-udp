defmodule BalanceManager do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:ok, %{balance: 0}}
  end

  def get_balance(pid) do
    GenServer.call(pid, :get_balance)
  end

  def got_paid(pid, amount) do
    GenServer.cast(pid, {:got_paid, amount})
  end

  def sent_payment(pid, amount) do
    GenServer.cast(pid, {:sent_payment, amount})
  end

  def handle_call(:get_balance, _from, state) do
    {:reply, Map.get(state, :balance), state}
  end

  def handle_cast({:got_paid, amount}, state) do
    {_, balance} = Map.get_and_update(state, :balance, fn(x) -> {x, (x || 0) + amount} end)
    {:noreply, balance}
  end

  def handle_cast({:sent_payment, amount}, state) do
    {_, balance} = Map.get_and_update(state, :balance, fn(x) -> {x, (x || 0) - amount} end)
    {:noreply, balance}
  end

end