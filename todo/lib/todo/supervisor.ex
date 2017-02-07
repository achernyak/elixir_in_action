defmodule Todo.Supervisor do
  use Supervisor

  def init(_) do
    processes = [worker(Todo.Cache, [])]
    supervisor(processes, strategy: :one_for_one)
  end
end
