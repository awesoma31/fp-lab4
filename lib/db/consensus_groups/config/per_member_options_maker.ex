defmodule RaftDB.ConsensusGroups.Config.PerMemberOptionsMaker do
  @moduledoc """
  Defines a behaviour for modules that provide the creation of per-member options
  for consensus groups in a Raft-based system.
  """

  alias RaftDB.Raft.Node, as: RaftNode

  @callback make(name :: atom) :: [RaftNode.option()]
end
