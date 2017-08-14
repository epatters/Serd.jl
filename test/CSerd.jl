module TestCSerd
using Base.Test
using Serd.CSerd

include("./data/turtle_ex1.jl")

# Reader
########

# Test read of triples only.
stmts = SerdStatement[]
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, nothing, nothing, statement_sink, nothing)
serd_reader_read_string(reader, TurtleEx1.turtle)
@test stmts == TurtleEx1.serd_triples

# Test manual free of reader (not necessary but allowed).
serd_reader_free(reader)
@test reader.ptr == C_NULL

# Test read of quads with default graph.
stmts = SerdStatement[]
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, nothing, nothing, statement_sink, nothing)
serd_reader_set_default_graph(reader, SerdNode("ex:graph", SERD_CURIE))
serd_reader_read_string(reader, TurtleEx1.turtle)
@test stmts == TurtleEx1.serd_quads

# Test read of base, prefix, and triples.
bases, prefixes, stmts = SerdNode[], Tuple{SerdNode,SerdNode}[], SerdStatement[]
base_sink = uri -> push!(bases, uri)
prefix_sink = (name, uri) -> push!(prefixes, (name,uri))
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, base_sink, prefix_sink, statement_sink, nothing)
serd_reader_read_string(reader, TurtleEx1.turtle)
@test bases == []
@test prefixes == TurtleEx1.serd_prefixes
@test stmts == TurtleEx1.serd_triples

# Writer
########

# Test write of single triple.
buf = IOBuffer()
writer = serd_writer_new(SERD_TURTLE, SerdStyles(0), buf)
serd_writer_write_statement(writer, TurtleEx1.serd_triples[1])
text = String(take!(buf))
@test text == """
<http://www.w3.org/TR/rdf-syntax-grammar>
	dc:title \"RDF/XML Syntax Specification (Revised)\""""

# Test manual free of writer (not necessary but allowed).
serd_writer_free(writer)
@test writer.ptr == C_NULL
@test writer.env == C_NULL

end
