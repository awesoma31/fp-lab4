use Croma
alias Croma.TypeGen, as: TG

defmodule RaftDB.Raft.Types.RPC.AppendEntriesRequest do
  @moduledoc """
  Type for request on server's append entries
  """

  alias RaftDB.Raft.Log.Entry
  alias RaftDB.Raft.Types.{LogIndex, LogInfo, TermNumber}
  alias RaftDB.Raft.Utils.Monotonic

  use Croma.Struct,
    fields: [
      leader_pid: Croma.Pid,
      term: TermNumber,
      prev_log: LogInfo,
      entries: TG.list_of(Entry),
      i_leader_commit: LogIndex,
      leader_timestamp: Monotonic
    ]
end
