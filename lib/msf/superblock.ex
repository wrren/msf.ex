defmodule MSFFormat.Superblock do
  @moduledoc """
  Describes an MSF superblock, and allows it to be deserialized from a binary input.
  """
  alias MSFFormat.Superblock
  defstruct [:block_size, :free_block_map_block, :num_blocks, :num_directory_bytes, :block_map_address]

  @size                         56
  @valid_block_sizes            [512, 1024, 2048, 4096]
  @valid_free_block_map_blocks  [1, 2]

  @doc """
  Read an MSF superblock from the given IO device.
  """
  def read(device) do
    case IO.binread(device, @size) do
      {:error, reason}  -> {:error, reason}
      binary            -> deserialize(binary)
    end
  end

  @doc """
  Deserialize an MSF superblock from the given binary
  """
  def deserialize(<<
    "Microsoft C/C++ MSF 7.00\r\n" :: binary,
    0x1A4453000000        :: 48,
    block_size            :: 32-little-unsigned,
    free_block_map_block  :: 32-little-unsigned,
    num_blocks            :: 32-little-unsigned,
    num_directory_bytes   :: 32-little-unsigned,
    _unknown              :: 32-little-unsigned,
    block_map_address     :: 32-little-unsigned
    >>) when block_size in @valid_block_sizes and free_block_map_block in @valid_free_block_map_blocks do
      {:ok, %Superblock{
        block_size:             block_size,
        free_block_map_block:   free_block_map_block,
        num_blocks:             num_blocks,
        num_directory_bytes:    num_directory_bytes,
        block_map_address:      block_map_address
      }}
  end
  def deserialize(_),
    do: {:error, :invalid_format}
end
