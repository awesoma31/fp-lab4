defmodule JustAnInt do
  @moduledoc false
  @behaviour RaftDB.Raft.StateMachine.Statable
  def new, do: 0
  def command(i, {:set, j}), do: {i, j}
  def command(i, :inc), do: {i, i + 1}
  def query(i, :get), do: i
end
