use Croma
alias Croma.TypeGen, as: TG

defmodule RaftDB.ConsensusGroups.Types.ConsensusNodesPair do
  @moduledoc """
  A module representing the ConsensusNodesPair type in the RaftDB consensus groups.
  """

  use Croma.SubtypeOfTuple, elem_modules: [Croma.Atom, TG.list_of(Croma.Atom)]
end
