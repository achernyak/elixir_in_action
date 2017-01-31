defmodule EnumStreams do
  def filtered_lines!(path) do
    File.stream!(path)
    |> Stream.map(&String.replace(&1, "\n", ""))
  end

  def lines_lengths!(path) do
    filtered_lines!(path)
    |> Enum.map(&String.length/1)
  end
  
end
