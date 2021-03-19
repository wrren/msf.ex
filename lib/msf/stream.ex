defmodule MSFFormat.Stream do
  @moduledoc """
  Allows an MSF stream to be read one block at a time.
  """
  defstruct [:id, :msf, :index]

  def new(id, msf),
    do: %MSFFormat.Stream{id: id, msf: msf, index: 0}

  @doc """
  Read another block of data from this MSF stream
  """
  def read(%MSFFormat.Stream{id: id, msf: %MSFFormat{directory: directory} = msf, index: index} = stream) do
    with  {:ok, block}  <- MSFFormat.StreamDirectory.get_stream_block(directory, id, index),
          {:ok, data}   <- MSFFormat.read_block(msf, block) do
      {:ok, %{stream | index: index + 1}, data}
    else
      {:error, :bad_block_index}  -> {:error, :no_more_data}
      other                       -> other
    end
  end

  @doc """
  Read the entire stream's contents from the beginning.
  """
  def read_all(%MSFFormat.Stream{id: id, msf: %MSFFormat{directory: directory}} = stream) do
    with {:ok, size} <- MSFFormat.StreamDirectory.size(directory, id) do
      read_all(read(%{stream | index: 0}), size, [])
    end
  end
  def read_all({:ok, stream, data}, size, out),
    do: read_all(read(stream), size, [data | out])
  def read_all({:error, :no_more_data}, size, out) do
    data = Enum.reduce(Enum.reverse(out), <<>>, fn(b, out) -> out <> b end)
    <<stream_data :: binary-size(size), _rest :: binary>> = data
    {:ok, stream_data}
  end
  def read_all(other, _size, _out),
    do: other
end
