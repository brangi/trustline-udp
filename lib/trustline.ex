defmodule Trustline do

  @commands %{
    "exit" => "Exit Trustline",
    "pay" => "Pay your trust party - separate cmd word and the amount with a space. Eg: 'pay 10' ",
    "balance" => "Check your balance"
  }

  def main(opts) do
    options = get_args(opts)
    {_, pid_balance} = BalanceManager.start_link
    OptionValues.start(ip_trustee: options[:ipTrustee],
                       port_trustee: options[:portTrustee],
                       pid_balance: pid_balance)

    spawn(fn -> open_session options[:portHost] end)
    IO.puts "Welcome to your trustline!"
    commands()
    receive_command()
  end

  def get_args(args) do
    {args, _, _} = OptionParser.parse(args,
      switches: [
        portHost: :integer,
        ipTrustee: :string,
        portTrustee: :integer
      ]
    )
    args
  end

  def get_list_io_string(str, index) do
    str
    |> String.split(~r{\s+})
    |> Enum.join(" ")
    |> String.split(" ", trim: true)
    |> Enum.at(index)
    |> String.downcase
  end

  defp receive_command do
    io_str = IO.gets("\n> ")
    cmd = get_list_io_string(io_str, 0)
    io_string_list = io_str
                     |> String.split(~r{\s+})
                     |> Enum.join(" ")
                     |> String.split(" ", trim: true)

    case Enum.count(io_string_list) do
      1 -> execute_command(cmd, "")
      2 ->
        arg = get_list_io_string(io_str, 1)
        execute_command(cmd, arg)
    end


  end

  defp execute_command("balance", _arg) do
    pid_balance = OptionValues.get(:pid_balance)
    balance  = BalanceManager.get_balance(pid_balance)
    IO.puts balance
    receive_command()
  end

  defp execute_command("exit", _arg) do
    IO.puts "\nGood Bye."
  end

  defp execute_command("pay", arg) do
    pay_to_trustee(arg)
    receive_command()
  end

  defp commands do
    @commands
    |> Enum.map(fn({command, description}) ->
      IO.puts("#{command} - #{description}")
    end)
  end

  def open_session(port) do
    server = Socket.UDP.open!(port)
    connector(server)
  end

  def connector(server) do
    {data, _} = server |> Socket.Datagram.recv!
    IO.puts "You were paid #{data}!"
    resolve_payment(data)
    connector(server)
  end

  def resolve_payment(amount) do
    {money, _} = Integer.parse(amount)
    OptionValues.get(:pid_balance) |> BalanceManager.got_paid(money)
  end

  def pay_to_trustee(amount) do
    case Integer.parse(amount) do
      {money, _} ->
        case money <= 0 do
          true-> IO.puts("Sorry you cannot send negatives")
          _->
            ip_trustee  = case OptionValues.get(:ip_trustee) do
              nil -> {127, 0, 0, 1}
              ## "102.32.3.4" -> ["102", "32", "3", "4"] -> parse string part into
              ## int -> {102, ok} -> and get the value of the result elem(res, 0)
              ## - >  final result = {102,......}
              _ -> { OptionValues.get(:ip_trustee) |> String.split(".")
                     |> Enum.at(0) |> Integer.parse |> elem(0),
                     OptionValues.get(:ip_trustee) |> String.split(".")
                     |> Enum.at(1) |> Integer.parse |> elem(0),
                     OptionValues.get(:ip_trustee) |> String.split(".")
                     |> Enum.at(2) |> Integer.parse |> elem(0),
                     OptionValues.get(:ip_trustee) |> String.split(".")
                     |> Enum.at(3) |> Integer.parse |> elem(0)
                   }
            end
            server = Socket.UDP.open!
            Socket.Datagram.send!(server, amount, {ip_trustee, OptionValues.get(:port_trustee) })
            OptionValues.get(:pid_balance) |> BalanceManager.sent_payment(money)
        end
      _error  -> IO.puts("Error parsing money values")
    end

  end

end
