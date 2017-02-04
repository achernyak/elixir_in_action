defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init
      loop(callback_module, initial_state)
    end)
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self})

    receive do
      {:response, response} ->
	response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(
          request,
          current_state
        )
        send(caller, {:response, response})

        loop(callback_module, new_state)
      {:cast, request} ->
	new_state = callback_module.handle_cast(
	request,
	current_state
      )
	loop(callback_module, new_state)
    end
  end
end

defmodule TodoServer do
  def start do
    ServerProcess.start(TodoServer)
  end

  def init do
    TodoList.new
  end

  def add_entry(todo_server, new_entry) do
    ServerProcess.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    ServerProcess.call(todo_server, {:entries, self, date})
  end

  def update_entry(todo_server, new_entry) do
    ServerProcess.cast(todo_server, {:update_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    SErverProcess.cast(todo_server, {:delete_entry, entry_id})
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, new_entry}, todo_list) do
    TodoList.update_entry(todo_list, new_entry)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    TodoList.delete_entry(todo_list, entry_id)
  end

  def handle_call({:entries, date}, todo_list) do
    {TodoList.entries(todo_list, date), todo_list}
  end
end

defmodule TodoList do
  defstruct auto_id: 1, entries: HashDict.new

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      &add_entry(&2, &1)
    )
  end

  def add_entry(
    %TodoList{entries: entries, auto_id: auto_id} = todo_list,
    entry
  ) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = HashDict.put(entries, auto_id, entry)

    %TodoList{todo_list |
	      entries: new_entries,
	      auto_id: auto_id + 1
    }
  end

  def entries(%TodoList{entries: entries}, date) do
    entries
    |> Stream.filter(fn({_, entry}) ->
      entry.date == date
    end)
    |>Enum.map(fn({_, entry}) ->
      entry
    end)
  end
  
  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn(_) -> new_entry end)
  end
 
  def update_entry(
    %TodoList{entries: entries} = todo_list,
    entry_id,
    updater_fn
  )do
    case entries[entry_id] do
      nil -> todo_list

      old_entry ->
	old_entry_id = old_entry.id
	new_entry = %{id: ^old_entry_id} = updater_fn.(old_entry)
	new_entries = HashDict.put(entries, new_entry.id, new_entry)
	%TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(
    %TodoList{entries: entries} = todo_list,
    entry_id
  ) do
    %TodoList{todo_list | entries: HashDisc.delete(entries, entry_id)}
  end
end

defmodule TodoList.CsvImporter do
  def import(file_name) do
    file_name
    |> read_lines
    |> create_entries
    |> TodoList.new
  end

  defp read_lines(file_name) do
    file_name
    |> File.stream!
    |> Stream.map(&String.replace(&1, "\n", ""))
  end

  defp create_entries(lines) do
    lines
    |> Stream.map(&extract_fields/1)
    |> Stream.map(&create_entry/1)
  end

  defp extract_fields(line) do
    line
    |> String.split(",")
    |> convert_date
  end

  defp convert_date([date_string, title]) do
    {parse_date(date_string), title}
  end

  defp parse_date(date_string) do
    date_string
    |> String.split("/")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  defp create_entry({date, title}) do
    %{date: date, title: title}
  end
end

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_, :halt), do: :ok
end
