defmodule Mix.Tasks.Raft do
  use Mix.Task

  @shortdoc "Interactive CLI"

  alias RaftDB.ConsensusGroups.GroupApplication
  alias RaftDB.Raft.Node, as: RaftNode

  def run(_args) do
    Application.ensure_all_started(:raft_db)
    loop(%{})
  end

  # MAIN MENU
  defp loop(state) do
    IO.puts("""
    1) Connect to node
    2) Activate this node
    3) Create consensus group
    4) Query group
    5) Command group
    6) Exit
    """)

    case IO.gets("> ") |> String.trim() do
      "1" -> connect_menu(state) |> loop()
      "2" -> activate_menu(state) |> loop()
      "3" -> create_group_menu(state) |> loop()
      "4" -> query_menu(state) |> loop()
      "5" -> command_menu(state) |> loop()
      "6" -> IO.puts("Bye!")
      _ -> loop(state)
    end
  end

  # CONNECT TO ANOTHER NODE
  defp connect_menu(state) do
    input =
      IO.gets("Enter node (example: 1@laptop): ")
      |> String.trim()

    node_name = String.to_atom(input)

    case Node.connect(node_name) do
      true ->
        IO.puts("Connected to #{inspect(node_name)}")
        state

      false ->
        IO.puts("Failed to connect to #{inspect(node_name)}")
        state

      :ignored ->
        IO.puts("Already connected or this is the same node (ignored)")
        state
    end
  end

  # ACTIVATE THIS NODE
  defp activate_menu(state) do
    zone = IO.gets("Enter zone name: ") |> String.trim()
    GroupApplication.activate(zone)
    IO.puts("Node activated in #{zone}")
    state
  end

  # CREATE CONSENSUS GROUP
  defp create_group_menu(state) do
    name =
      IO.gets("Group name (atom): ")
      |> String.trim()
      |> String.to_atom()

    members =
      IO.gets("Members count: ")
      |> String.trim()
      |> String.to_integer()

    config = RaftNode.make_config(JustAnInt)

    GroupApplication.add_consensus_group(name, members, config)

    IO.puts("Group #{name} created.")
    state
  end

  # QUERY GROUP
  defp query_menu(state) do
    group =
      IO.gets("Group name: ")
      |> String.trim()
      |> String.to_atom()

    query =
      IO.gets("Query (:get): ")
      |> String.trim()
      |> String.to_atom()

    IO.inspect(GroupApplication.query(group, query))
    state
  end

  # COMMAND GROUP
  defp command_menu(state) do
    group =
      IO.gets("Group name: ")
      |> String.trim()
      |> String.to_atom()

    cmd =
      IO.gets("Command (:inc or {:set, value}): ")
      |> String.trim()

    command = Code.eval_string(cmd) |> elem(0)

    IO.inspect(GroupApplication.command(group, command))
    state
  end
end
