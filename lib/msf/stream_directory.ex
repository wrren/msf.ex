defmodule MSFFormat.StreamDirectory do
  alias MSFFormat.{
    Superblock,
    StreamDirectory
  }
  defstruct [:num_streams, :stream_sizes, :stream_blocks]

  @doc """
  Get the number of blocks used by the given stream.
  """
  def length(%StreamDirectory{stream_blocks: streams}, stream_id) do
    case Enum.at(streams, stream_id) do
      blocks when is_list(blocks) -> {:ok, length(blocks)}
      nil                         -> {:error, :bad_stream_id}
    end
  end

  @doc """
  Get the total size of the given stream.
  """
  def size(%StreamDirectory{stream_sizes: stream_sizes}, stream_id) do
    case Enum.at(stream_sizes, stream_id) do
      size when is_integer(size) -> {:ok, size}
      nil                        -> {:error, :bad_stream_id}
    end
  end

  @doc """
  Get the block at the given index for the stream with the given ID.
  """
  def get_stream_block(%StreamDirectory{stream_blocks: streams}, stream_id, index) do
    with  {:streams, blocks} when is_list(blocks) <- {:streams, Enum.at(streams, stream_id)},
          {:blocks, block} when block != nil      <- {:blocks, Enum.at(blocks, index)} do
      {:ok, block}
    else
      {:streams, nil} -> {:error, :bad_stream_id}
      {:blocks, nil}  -> {:error, :bad_block_index}
    end
  end

  @doc """
  Read an MSF stream directory
  """
  def read(%MSFFormat{superblock: %Superblock{block_size: block_size, block_map_address: address, num_directory_bytes: directory_size}, device: device} = msf) do
    with  {:ok, _position}              <- :file.position(device, block_size * address),
          data when not is_tuple(data)  <- IO.binread(device, ceil(directory_size / block_size) * 4) do
      read(msf, directory_size, data, [])
    end
  end
  def read(%MSFFormat{superblock: superblock} = msf, 0, _, out) do
    with {:ok, directory} <- deserialize(superblock, Enum.join(Enum.reverse(out))) do
      {:ok, %{msf | directory: directory}}
    end
  end
  def read(%MSFFormat{superblock: %Superblock{block_size: block_size, num_directory_bytes: directory_size}} = msf, size, <<index :: 32-little-unsigned, rest :: binary>>, out) do
    with {:ok, data} <- MSFFormat.read_block(msf, index, min(block_size, directory_size)) do
      read(msf, size - min(block_size, directory_size), rest, [data | out])
    end
  end

  @doc """
  Deserialize a stream directory from the given binary blob
  """
  def deserialize(%Superblock{} = superblock, <<num_streams :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(superblock, %StreamDirectory{num_streams: num_streams, stream_sizes: [], stream_blocks: []}, rest)
  def deserialize(%Superblock{} = superblock, %StreamDirectory{num_streams: num, stream_sizes: stream_sizes} = directory, <<size :: 32-little-unsigned, rest :: binary>>) when length(stream_sizes) < num,
    do: deserialize(superblock, %{directory | stream_sizes: [size | stream_sizes]}, rest)
  def deserialize(%Superblock{block_size: block_size}, %StreamDirectory{num_streams: num, stream_sizes: sizes, stream_blocks: blocks} = directory, bin) when length(blocks) < num do
    sizes
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, bin, []}, fn(size, {:ok, bin, blocks}) ->
      case deserialize_block(ceil(size / block_size), bin) do
        {:ok, block, bin} ->
          {:cont, {:ok, bin, Enum.concat(blocks, [block])}}
        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} ->
        {:error, reason}
      {:ok, _rest, blocks} ->
        {:ok, %{directory | stream_sizes: Enum.reverse(sizes), stream_blocks: blocks}}
    end
  end

  @doc """
  Deserialize a set of block indices
  """
  def deserialize_block(count, bin),
    do: deserialize_block(count, bin, [])
  def deserialize_block(0, bin, out),
    do: {:ok, Enum.reverse(out), bin}
  def deserialize_block(count, <<block :: 32-little-unsigned, rest :: binary>>, out),
    do: deserialize_block(count - 1, rest, [block | out])
  def deserialize_block(_, _, _),
    do: {:error, :invalid_format}
end
