""" High-level interface to C library Serd.
"""
module Serd

import Base: convert
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

convert(::Type{SerdNode}, node::Resource) = SerdNode(node.uri, SERD_URI)
convert(::Type{SerdNode}, node::Blank) = SerdNode(node.name, SERD_BLANK)

convert(::Type{SerdStatement}, stmt::Triple) =
  convert_to_serd(Nullable{Node}(), stmt.subject, stmt.predicate, stmt.object)
convert(::Type{SerdStatement}, stmt::Quad) =
  convert_to_serd(stmt.graph, stmt.subject, stmt.predicate, stmt.object)
  
function convert_to_serd(graph, subject, predicate, object)
  graph = isnull(graph) ? nothing : convert(SerdNode, graph)
  subject = convert(SerdNode, subject)
  predicate = convert(SerdNode, predicate)
  if isa(object, Literal)
    object_datatype = isa(object.value, AbstractString) ? 
      nothing : SerdNode(rdf_datatype(typeof(object.value)), SERD_URI)
    object_lang = isempty(object.language) ?
      nothing : SerdNode(object.language, SERD_LITERAL)
    object = SerdNode(string(object.value), SERD_LITERAL)
  else
    object = convert(SerdNode, object)
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

function convert(::Type{Node}, node::SerdNode)
  if node.typ == SERD_URI || node.typ == SERD_CURIE
    Resource(node.value)
  elseif node.typ == SERD_BLANK
    Blank(node.value)
  else
    error("Cannot convert SERD node of type $(node.typ)")
  end
end

function convert(::Type{Statement}, stmt::SerdStatement)
  subject = convert(Node, stmt.subject)
  predicate = convert(Node, stmt.predicate)
  object = if stmt.object.typ == SERD_LITERAL
    if isnull(stmt.object_datatype)
      lang = isnull(stmt.object_lang) ? "" : get(stmt.object_lang).value
      Literal(stmt.object.value, lang)
    else
      typ = julia_datatype(get(stmt.object_datatype).value)
      Literal(parse(typ, stmt.object.value))
    end
  else
    convert(Node, stmt.object)
  end
  if isnull(stmt.graph)
    Triple(subject, predicate, object)
  else
    Quad(subject, predicate, object, convert(Node, get(stmt.graph)))
  end
end


end
