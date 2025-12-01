use Croma

defmodule RaftDB.ConsensusGroups.Config.RaftConfigConstructor do
  @moduledoc """
  A behaviour module for constructing Raft configuration objects.
  """

  alias RaftDB.Raft.Types.Config

  @callback make(consensus_group_name :: atom) :: Config.t()
end
