defmodule Todo.ProcessRegistry do
  use GenServer

  def init(_) do
    {:ok, HashDict.new}
  end

  def handl_call({:register_name, key, pid}, _, process_registry) do
    case HashDict.get(process_registry, key) do
      nil ->
	Process.monitor(pid)
	{:reply, :yes, HashDict.put(process_registry, key, pid)}
      _ ->
	{:reply, :no, process_registry}
    end
  end

  def handle_call({:whereis_name, key}, _, process_registry) do
    {
      :reply,
      HashDict.get(process_registry, key, :undefined),
      process_registry
    }
  end
end
