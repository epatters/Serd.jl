module TestSerd
using Base.Test
using Serd, Serd.CSerd

# Node conversion
@test convert(SerdNode, Resource("rdf:type")) == SerdNode("rdf:type", SERD_URI)
@test convert(Node, SerdNode("rdf:type", SERD_URI)) == Resource("rdf:type")

@test convert(SerdNode, Blank("?x")) == SerdNode("?x", SERD_BLANK)
@test convert(Node, SerdNode("?x", SERD_BLANK)) == Blank("?x")

# Statement conversion
triple = Triple(Resource("bob"), Resource("rdf:type"), Resource("Person"))
stmt = SerdStatement(
  0,
  SERD_NODE_NULL,
  SerdNode("bob", SERD_URI),
  SerdNode("rdf:type", SERD_URI),
  SerdNode("Person", SERD_URI),
  SERD_NODE_NULL,
  SERD_NODE_NULL,
)
@test convert(SerdStatement, triple) == stmt
@test convert(Statement, stmt) == triple

triple = Triple(Resource("bob"), Resource("name"), Literal("Bob"))
stmt = SerdStatement(
  0,
  SERD_NODE_NULL,
  SerdNode("bob", SERD_URI),
  SerdNode("name", SERD_URI),
  SerdNode("Bob", SERD_LITERAL),
  SERD_NODE_NULL,
  SERD_NODE_NULL,
)
@test convert(SerdStatement, triple) == stmt
@test convert(Statement, stmt) == triple

triple = Triple(Resource("bob"), Resource("age"), Literal(50))
stmt = SerdStatement(
 0,
 SERD_NODE_NULL,
 SerdNode("bob", SERD_URI),
 SerdNode("age", SERD_URI),
 SerdNode("50", SERD_LITERAL),
 SerdNode(Serd.XSD_INTEGER, SERD_URI),
 SERD_NODE_NULL,
)
@test convert(SerdStatement, triple) == stmt
@test convert(Statement, stmt) == triple

quad = Quad(Resource("bob"), Resource("friendly"), Literal(true), Resource("people"))
stmt = SerdStatement(
 0,
 SerdNode("people", SERD_URI),
 SerdNode("bob", SERD_URI),
 SerdNode("friendly", SERD_URI),
 SerdNode("true", SERD_LITERAL),
 SerdNode(Serd.XSD_BOOLEAN, SERD_URI),
 SERD_NODE_NULL,
)
@test convert(SerdStatement, quad) == stmt
@test convert(Statement, stmt) == quad

end
