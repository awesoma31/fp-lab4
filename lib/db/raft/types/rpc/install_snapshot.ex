use Croma

defmodule RaftDB.Raft.Types.RPC.InstallSnapshot do
  @moduledoc """
  Represents a snapshot installation request in the Raft consensus algorithm.

  This struct is used to encapsulate the necessary information for a node to install a snapshot from another node.
  It includes details about the current cluster members, the term number, the last committed log entry,
  the configuration, and any additional data associated with the snapshot.

  ## Fields

  - `members`: The current members of the Raft cluster.
  - `term`: The current term number of the leader.
  - `last_committed_entry`: The last committed log entry before the snapshot.
  - `config`: The configuration settings for the Raft protocol.
  - `data`: Any additional data associated with the snapshot.
  - `command_results`: The results of commands that have been executed.
  """

  alias RaftDB.Raft.Communication.Members
  alias RaftDB.Raft.Log.Entry
  alias RaftDB.Raft.Types.{CommandResults, Config, TermNumber}

  use Croma.Struct,
    fields: [
      members: Members,
      term: TermNumber,
      last_committed_entry: Entry,
      config: Config,
      data: Croma.Any,
      command_results: CommandResults
    ]
end
