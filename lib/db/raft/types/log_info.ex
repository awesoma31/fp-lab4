defmodule RaftDB.Raft.Types.LogInfo do
  @moduledoc """
  Log info type.
  """

  alias RaftDB.Raft.Types.{LogIndex, TermNumber}

  use Croma.SubtypeOfTuple,
    elem_modules: [
      TermNumber,
      LogIndex
    ]
end
