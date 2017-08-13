module TestCSerd
using Base.Test
using Serd.CSerd

include("./data/turtle_ex1.jl")

# Test read of triples only.
stmts = SerdStatement[]
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, nothing, nothing, statement_sink, nothing)
serd_reader_read_string(reader, turtle_ex1)
@test stmts == turtle_ex1_serd_triples

# Test manual free of reader (not necessary but allowed).
serd_reader_free(reader)
@test reader.ptr == C_NULL

# Test read of quads with default graph.
stmts = SerdStatement[]
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, nothing, nothing, statement_sink, nothing)
serd_reader_set_default_graph(reader, SerdNode("ex:graph", SERD_CURIE))
serd_reader_read_string(reader, turtle_ex1)
@test stmts == turtle_ex1_serd_quads

# Test read of base, prefix, and triples.
bases, prefixes, stmts = SerdNode[], Tuple{SerdNode,SerdNode}[], SerdStatement[]
base_sink = uri -> push!(bases, uri)
prefix_sink = (name, uri) -> push!(prefixes, (name,uri))
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, base_sink, prefix_sink, statement_sink, nothing)
serd_reader_read_string(reader, turtle_ex1)
@test bases == []
@test prefixes == turtle_ex1_serd_prefixes
@test stmts == turtle_ex1_serd_triples

end
