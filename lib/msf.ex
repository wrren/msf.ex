defmodule MSFFormat do
  @moduledoc """
  Describes the MSF file format and functions for deserializing it from binary or file inputs.
  """
  defstruct [:device, :superblock, :directory]

  @doc """
  Read an MSF file from the given device. Does not read the entire file, only the data required to
  read specific blocks.
  """
  def read(device) do
    with {:ok, superblock} <- MSFFormat.Superblock.read(device) do
      MSFFormat.StreamDirectory.read(%MSFFormat{device: device, superblock: superblock})
    end
  end

  @doc """
  Attempt to read the block at the given index from the given MSF file. If a `size` parameter is given, the
  specified number of bytes will be read, otherwise the entire contents of the block will be read.
  """
  def read_block(%MSFFormat{superblock: %MSFFormat.Superblock{block_size: block_size}} = msf, index),
    do: read_block(msf, index, block_size)
  def read_block(%MSFFormat{superblock: %MSFFormat.Superblock{block_size: block_size}, device: device}, index, size) do
    with  {:ok, _position}            <- :file.position(device, index * block_size),
          data when is_binary(data)   <- IO.binread(device, size) do
      {:ok, data}
    end
  end

  @doc """
  Open a stream for reading. Call MSFFormat.Stream.read to read blocks from the stream in sequence.
  """
  def open_stream(%MSFFormat{directory: directory} = msf, stream_id) do
    case MSFFormat.StreamDirectory.length(directory, stream_id) do
      {:error, :bad_stream_id}  -> {:error, :bad_stream_id}
      {:ok, _length}            -> {:ok, MSFFormat.Stream.new(stream_id, msf)}
    end
  end


  @doc """
  Close the underlying IO device for the given MSF file.
  """
  def close(%MSFFormat{device: device}),
    do: File.close(device)

  @doc """
  Open and read the MSF file at the given path.
  """
  def open(path) when is_binary(path) do
    with {:ok, device}   <- File.open(path, [:binary, :read]) do
      read(device)
    end
  end
end
