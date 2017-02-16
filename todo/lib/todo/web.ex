defmodule Todo.Web do
  def start_server do
    Plug.Adapters.Cowboy.http(__MODULE__, nil, port: 5454)
  end
end
