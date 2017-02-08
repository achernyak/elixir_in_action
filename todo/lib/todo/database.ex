defmodule Todo.Database do
  @pool_size 3
  
  def start_link(db_folder) do
    IO.puts("Startind database")

    Todo.PoolSupervisor.start_link(db_folder, @pool_size)
  end

  def store(key, data) do
    key
    |> choose_worker
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker
    |> Todo.DatabaseWorker.get(key)
  end

  defp choose_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

  def init(db_folder) do
    {:ok, start_worker(db_folder)}
  end

  defp start_worker(db_folder) do
    for index <- 1..3, into: HashDict.new do
      {:ok, pid} = Todo.DatabaseWorker.start_link(db_folder)
      {index - 1, pid}
    end
  end

  def handle_call({:choose_worker, key}, _, workers) do
    worker_key = :erlang.phash2(key, 3)
    {:reply, HashDict.get(workers, worker_key), workers}
  end

  def handle_info(:stop, workers) do
    workers
    |> HashDict.values
    |> Enum.each(&send(&1, :stop))

    {:stop, :normal, HashDict.new}
  end

  def handle_info(_, state), do: {:noreply, state}
end
