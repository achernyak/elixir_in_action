defmodule Todo.Server do
  use GenServer
  
  def start(name) do
    GenServer.start(Todo.Server, name)
  end
  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def update_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:update_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end

  def init(name) do
    {:ok, { name, Todo.Database.get(name) || Todo.List.new}}
  end

  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_state = Todo.List.add_entry(todo_list, new_entry)
    {:noreply, {name,  new_state}}
  end

  def handle_cast({:update_entry, new_entry}, {name, todo_list}) do
    new_state = Todo.List.update_entry(todo_list, new_entry)
    {:noreply, {name, new_state}}
  end

  def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
    new_state = Todo.List.delete_entry(todo_list, entry_id)
    {:noreply, {name, new_state}}
  end

  def handle_call({:entries, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {name, todo_list} 
    }
  end

  def handle_info(:stop, state), do: {:stop, :normal, state}
  def handle_info(_, state), do {:noreply, state}
end
