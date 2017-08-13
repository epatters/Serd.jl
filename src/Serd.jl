""" High-level interface to C library Serd.
"""
module Serd
export to_serd, from_serd

using Reexport

include("CSerd.jl")
include("RDF.jl")
using .CSerd
@reexport using .RDF

# Data types: Julia interface to C interface
############################################

const NS_XSD = "http://www.w3.org/2001/XMLSchema#"
const XSD_BOOLEAN = "$(NS_XSD)boolean"
const XSD_INTEGER = "$(NS_XSD)integer"
const XSD_DECIMAL = "$(NS_XSD)decimal"
const XSD_DOUBLE = "$(NS_XSD)double"

rdf_datatype(::Type{Bool}) = XSD_BOOLEAN
rdf_datatype(::Type{T}) where T <: Integer = XSD_INTEGER
rdf_datatype(::Type{T}) where T <: Real = XSD_DECIMAL

to_serd(node::Resource) = SerdNode(node.uri, SERD_URI)
to_serd(node::Blank) = SerdNode(node.name, SERD_BLANK)
to_serd(stmt::Triple) = to_serd(
  Nullable{Node}(), stmt.subject, stmt.predicate, stmt.object)
to_serd(stmt::Quad) = to_serd(
  Nullable(stmt.graph), stmt.subject, stmt.predicate, stmt.object)
  
function to_serd(graph::Nullable{T} where T <: Node,
                 subject::Node, predicate::Node, object::Node)
  graph = isnull(graph) ? Nullable{SerdNode}() : to_serd(get(graph))
  subject = to_serd(subject)
  predicate = to_serd(predicate)
  if isa(object, Literal)
    object_datatype = isa(object.value, AbstractString) ? 
      nothing : SerdNode(rdf_datatype(typeof(object.value)), SERD_URI)
    object_lang = isempty(object.language) ?
      nothing : SerdNode(object.language, SERD_LITERAL)
    object = SerdNode(string(object.value), SERD_LITERAL)
  else
    object = to_serd(object)
    object_datatype = nothing
    object_lang = nothing
  end
  SerdStatement(0, graph, subject, predicate, object, object_datatype, object_lang)
end

# Data types: C interface to Julia interface
############################################

const JULIA_TYPES = Dict{String,Type}(
  XSD_BOOLEAN => Bool,
  XSD_INTEGER => Int,
  XSD_DECIMAL => Float64,
  XSD_DOUBLE => Float64
)
julia_datatype(datatype::String) = JULIA_TYPES[datatype]

function from_serd(node::SerdNode)::Node
  if node.typ == SERD_URI || node.typ == SERD_CURIE
    Resource(node.value)
  elseif node.typ == SERD_BLANK
    Blank(node.value)
  else
    error("Cannot convert SERD node of type $(node.typ)")
  end
end

function from_serd(stmt::SerdStatement)::Statement
  subject = from_serd(stmt.subject)
  predicate = from_serd(stmt.predicate)
  object = if stmt.object.typ == SERD_LITERAL
    if isnull(stmt.object_datatype)
      if isnull(stmt.object_lang)
        Literal(stmt.object.value)
      else
        Literal(stmt.object.value, get(stmt.object_lang).value)
      end
    else
      typ = julia_datatype(get(stmt.object_datatype).value)
      Literal(parse(typ, stmt.object.value))
    end
  else
    from_serd(stmt.object)
  end
  if isnull(stmt.graph)
    Triple(subject, predicate, object)
  else
    Quad(subject, predicate, object, from_serd(get(stmt.graph)))
  end
end


end