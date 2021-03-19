# MSF

Elixir library for opening and decoding MSF (Multi-Stream Format) files. MSF is the backing format for file types
such as Microsoft PDB.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `msf_format` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:msf_format, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/msf](https://hexdocs.pm/msf).

## Usage

```elixir
# Open an MSF file for reading
{:ok, msf} = MSFFormat.open("/path/to/msf")

# Read a single block (block 0) from the file
{:ok, block}  = MSFFormat.read_block(msf, 0)

# Open stream 0 for reading
{:ok, stream} = MSFFormat.open_stream(msf, 0)

# Read a single block from the given stream
{:ok, stream, data} = MSFFormat.Stream.read(stream)

# Read all data from the given stream
{:ok, all_data} = MSFFormat.Stream.read_all(stream)

# Close the MSF file
:ok = MSFFormat.close(msf)
```