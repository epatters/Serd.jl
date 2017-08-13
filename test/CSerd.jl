module TestCSerd
using Base.Test
using Serd.CSerd

# https://www.w3.org/TeamSubmission/turtle/#sec-examples
const turtle_ex1 = """
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .
@prefix ex: <http://example.org/stuff/1.0/> .

<http://www.w3.org/TR/rdf-syntax-grammar>
  dc:title "RDF/XML Syntax Specification (Revised)" ;
  ex:editor [
    ex:fullname "Dave Beckett";
    ex:homePage <http://purl.org/net/dajobe/>
  ] .
"""

stmts = SerdStatement[]
statement_sink = stmt -> push!(stmts, stmt)
reader = serd_reader_new(SERD_TURTLE, nothing, nothing, statement_sink, nothing)
serd_reader_read_string(reader, turtle_ex1)

@test stmts == [
  SerdStatement(
    0,
    nothing,
    SerdNode("http://www.w3.org/TR/rdf-syntax-grammar", SERD_URI),
    SerdNode("dc:title", SERD_CURIE),
    SerdNode("RDF/XML Syntax Specification (Revised)", SERD_LITERAL),
    nothing,
    nothing,
  ),
  SerdStatement(
    SERD_ANON_O_BEGIN,
    nothing,
    SerdNode("http://www.w3.org/TR/rdf-syntax-grammar", SERD_URI),
    SerdNode("ex:editor", SERD_CURIE),
    SerdNode("b1", SERD_BLANK),
    nothing,
    nothing,
  ),
  SerdStatement(
    SERD_ANON_CONT,
    nothing,
    SerdNode("b1", SERD_BLANK),
    SerdNode("ex:fullname", SERD_CURIE),
    SerdNode("Dave Beckett", SERD_LITERAL),
    nothing,
    nothing,
  ),
  SerdStatement(
    SERD_ANON_CONT,
    nothing,
    SerdNode("b1", SERD_BLANK),
    SerdNode("ex:homePage", SERD_CURIE),
    SerdNode("http://purl.org/net/dajobe/", SERD_URI),
    nothing,
    nothing,
  ),
]

end
