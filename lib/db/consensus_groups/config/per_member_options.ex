use Croma

defmodule RaftDB.ConsensusGroups.Config.PerMemberOptions do
  @moduledoc """
  Provides functionality to build per-member options for consensus groups in a Raft-based system.
  """

  alias RaftDB.ConsensusGroups.Config.Config
  alias RaftDB.Raft.Node

  defun build(name :: atom) :: [Node.option()] do
    case Config.per_member_options() do
      nil -> []
      mod -> mod.make(name)
    end
    |> Keyword.put(:name, name)
  end
end
