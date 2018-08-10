module TestCSerd
using Test
using Serd.CSerd

import ..TurtleEx1

# Reader
########

# Test read of triples from file.
stmts = SerdStatement[]
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, nothing, nothing, statement_sink, nothing)
serd_reader_read_file(reader, TurtleEx1.turtle_path)
@test stmts == TurtleEx1.serd_triples

# Test read of triples from string.
stmts = SerdStatement[]
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, nothing, nothing, statement_sink, nothing)
serd_reader_read_string(reader, TurtleEx1.turtle)
@test stmts == TurtleEx1.serd_triples

# Test error handling.
@test_throws SerdException serd_reader_read_string(reader, "XXX")
errors = SerdStatus[]
serd_reader_set_error_sink(reader, status -> push!(errors, status))
@test_throws SerdException serd_reader_read_string(reader, "XXX")
@test errors == [ SERD_ERR_BAD_SYNTAX ]

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

function normalize_whitespace(text::AbstractString)
  text = replace(replace(text, r"\n+" => "\n"), r"\t" => "  ")
  string(strip(text), "\n") # Exactly one trailing newline.
end

# Test write of single triple.
buf = IOBuffer()
writer = serd_writer_new(SERD_TURTLE, SerdStyles(0), buf)
serd_writer_write_statement(writer, TurtleEx1.serd_triples[1])
serd_writer_finish(writer)
text = String(take!(buf))
@test normalize_whitespace(text) == """
<http://www.w3.org/TR/rdf-syntax-grammar>
  dc:title \"RDF/XML Syntax Specification (Revised)\" .
"""

# Test write of single quad.
serd_writer_write_statement(writer, TurtleEx1.serd_quads[1])
serd_writer_finish(writer)
text = String(take!(buf))
@test normalize_whitespace(text) == """
ex:graph {
   <http://www.w3.org/TR/rdf-syntax-grammar>
    dc:title \"RDF/XML Syntax Specification (Revised)\" .
 }
"""

# Test write of base URI and prefix.
serd_writer_set_base_uri(writer,
  SerdNode("http://example.org/stuff/1.0/", SERD_URI))
text = String(take!(buf))
@test text == "@base <http://example.org/stuff/1.0/> .\n"

serd_writer_set_prefix(writer,
  SerdNode("rdf", SERD_LITERAL),
  SerdNode("http://www.w3.org/1999/02/22-rdf-syntax-ns#", SERD_URI))
text = String(take!(buf))
@test text == "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"

# Test manual free of writer (not necessary but allowed).
serd_writer_free(writer)
@test writer.ptr == C_NULL
@test writer.env == C_NULL

end
