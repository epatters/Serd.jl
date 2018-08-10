module TurtleEx1
using Serd, Serd.CSerd, Serd.RDF

# https://www.w3.org/TeamSubmission/turtle/#sec-examples
const turtle_path = "data/turtle_ex1.ttl"
const turtle_alt_path = "data/turtle_ex1_alt.ttl" # roundtripped through Serd
const turtle = read(turtle_path, String)
const turtle_alt = read(turtle_alt_path, String)

const statements = Statement[
  Prefix("rdf"),
  Prefix("dc", "http://purl.org/dc/elements/1.1/"),
  Prefix("ex", "http://example.org/stuff/1.0/"),
  Triple(
    Resource("http://www.w3.org/TR/rdf-syntax-grammar"),
    Resource("dc", "title"),
    Literal("RDF/XML Syntax Specification (Revised)")),
  Triple(
    Resource("http://www.w3.org/TR/rdf-syntax-grammar"),
    Resource("ex", "editor"),
    Blank("b1")),
  Triple(
    Blank("b1"),
    Resource("ex", "fullname"),
    Literal("Dave Beckett")),
  Triple(
    Blank("b1"),
    Resource("ex", "homePage"),
    Resource("http://purl.org/net/dajobe/")),
]

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
