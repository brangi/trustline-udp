defmodule OptionValues do
  use GenServer

  def start(default \\ []) do
    GenServer.start(__MODULE__, default, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, { :get, key })
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def init(values) do
    { :ok, Enum.into(values, %{}) }
  end

  def handle_call({ :get, key }, _from, state) do
    { :reply, state[key], state }
  end

end