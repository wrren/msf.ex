defmodule MSFFormat.FreeBlockMap do
  @moduledoc """
  Represents a map of data blocks indicating which blocks are in use and
  which are not.
  """
  defstruct map: nil

  def deserialize(%MSFFormat.Superblock{block_size: block_size}, binary) do
    <<map :: binary-size(block_size), rest :: binary>> = binary
    {:ok, %MSFFormat.FreeBlockMap{map: map}, rest}
  end

  def is_block_used?(%MSFFormat.FreeBlockMap{map: map}, index) do
    prefix_size = index - 1
    <<_prefix :: size(prefix_size), block_status :: 1>> = map
    block_status == 1
  end
end
