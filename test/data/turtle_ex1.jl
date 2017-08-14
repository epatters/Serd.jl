module TurtleEx1
using Serd.CSerd

# https://www.w3.org/TeamSubmission/turtle/#sec-examples
const turtle = """
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

const serd_prefixes = [
  (SerdNode("rdf", SERD_LITERAL), SerdNode("http://www.w3.org/1999/02/22-rdf-syntax-ns#", SERD_URI)),
  (SerdNode("dc", SERD_LITERAL), SerdNode("http://purl.org/dc/elements/1.1/", SERD_URI)),
  (SerdNode("ex", SERD_LITERAL), SerdNode("http://example.org/stuff/1.0/", SERD_URI))
]

const serd_triples = [
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

const serd_quads = [
  SerdStatement(
    0,
    SerdNode("ex:graph", SERD_CURIE),
    SerdNode("http://www.w3.org/TR/rdf-syntax-grammar", SERD_URI),
    SerdNode("dc:title", SERD_CURIE),
    SerdNode("RDF/XML Syntax Specification (Revised)", SERD_LITERAL),
    nothing,
    nothing,
  ),
  SerdStatement(
    SERD_ANON_O_BEGIN,
    SerdNode("ex:graph", SERD_CURIE),
    SerdNode("http://www.w3.org/TR/rdf-syntax-grammar", SERD_URI),
    SerdNode("ex:editor", SERD_CURIE),
    SerdNode("b1", SERD_BLANK),
    nothing,
    nothing,
  ),
  SerdStatement(
    SERD_ANON_CONT,
    SerdNode("ex:graph", SERD_CURIE),
    SerdNode("b1", SERD_BLANK),
    SerdNode("ex:fullname", SERD_CURIE),
    SerdNode("Dave Beckett", SERD_LITERAL),
    nothing,
    nothing,
  ),
  SerdStatement(
    SERD_ANON_CONT,
    SerdNode("ex:graph", SERD_CURIE),
    SerdNode("b1", SERD_BLANK),
    SerdNode("ex:homePage", SERD_CURIE),
    SerdNode("http://purl.org/net/dajobe/", SERD_URI),
    nothing,
    nothing,
  ),
]

end
