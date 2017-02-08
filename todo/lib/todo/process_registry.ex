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

  def handle_info({:DOWN, _, :process, pid, _}, process_registry) do
    {:noreply, deregister_pid(process_registry, pid)}
  end

  defp deregister_pid(process_registry, pid) do
    Enum.reduce(
      process_registry,
      process_registry,
      fn
	({registered_alias, registered_process}, registry_acc) when registered_process == pid ->
	  HashDict.delete(registry_acc, registered_alias)

	(_, registry_acc) -> registry_acc
      end
    )
  end
end
