defmodule ProfileCache do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: :ets_profile_cache)
  end

  def cached(key, fun) do
    read_cached(key) ||
      GenServer.call(:ets_profile_cache, {:cached, key, fun})
  end

  defp read_cached(key) do
    case :ets.lookup(:ets_profile_cache, key) do
      [{^key, cached}] -> cached
      _ -> nil
    end
  end

  
  def init(_) do
    :ets.new(:ets_profile_cache, [:set, :named_table, :protected])
    {:ok, nil}
  end

  def handle_call({:cached, key, fun}, _, state) do
    {
      :reply,
      read_cached(key) || cache_response(key, fun),
      state
    }
  end

  defp cache_response(key, fun) do
    response = fun.()
    :ets.insert(:ets_profile_cache, {key, response})
    response
  end
end
