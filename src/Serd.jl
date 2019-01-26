module Serd
export RDF, read_rdf_file, read_rdf_string, write_rdf, write_rdf_statement,
  rdf_writer

using Nullables

include("CSerd.jl")
include("RDF.jl")
using .CSerd
using .RDF

# Reader
########

""" Read RDF from file.
"""
function read_rdf_file(path::String; kw...)::Vector{Statement}
  stmts = Statement[]
  read_rdf_file(path; kw...) do stmt
    push!(stmts, stmt)
  end
  stmts
end

""" Read RDF from string.
"""
function read_rdf_string(text::String; kw...)::Vector{Statement}
  stmts = Statement[]
  read_rdf_string(text; kw...) do stmt
    push!(stmts, stmt)
  end
  stmts
end

""" Read RDF from file in SAX (event-driven) style.
"""
function read_rdf_file(handler::Function, path::String;
                       syntax::String="turtle")::Nothing
  reader = rdf_reader(handler, syntax)
  serd_reader_read_file(reader, path)
  serd_reader_free(reader)
end

""" Read RDF from string in SAX (event-driven) style.
"""
function read_rdf_string(handler::Function, text::String;
                         syntax::String="turtle")::Nothing
  reader = rdf_reader(handler, syntax)
  serd_reader_read_string(reader, text)
  serd_reader_free(reader)
end

""" Create RDF reader with given event handler.
"""
function rdf_reader(handler::Function, syntax::String)::SerdReader
  base_sink(uri::SerdNode) = handler(BaseURI(uri.value))
  prefix_sink(name::SerdNode, uri::SerdNode) = handler(Prefix(name.value, uri.value))
  statement_sink(stmt::SerdStatement) = handler(from_serd(stmt))
  end_sink(node::SerdNode) = nothing # FIXME: What do with this?
  
  serd_reader_new(serd_syntax(syntax), base_sink, prefix_sink,
                  statement_sink, end_sink)
end

# Writer
########

""" Write RDF to IO stream.
"""
function write_rdf(io::IO, stmts::Vector{<:Statement};
                   syntax::String="turtle")::Nothing
  writer = rdf_writer(syntax, io)
  for stmt in stmts
    write_rdf_statement(writer, stmt)
  end
  close(writer)
end
function write_rdf(stmts::Vector{<:Statement}; kw...)
  write_rdf(stdout, stmts; kw...)
end

""" Write a single RDF statement.
"""
function write_rdf_statement(writer::SerdWriter, stmt::Statement)
  serd_writer_write_statement(writer, to_serd(stmt))
end
function write_rdf_statement(writer::SerdWriter, stmt::BaseURI)
  uri = SerdNode(stmt.uri, SERD_URI)
  serd_writer_set_base_uri(writer, uri)
end
function write_rdf_statement(writer::SerdWriter, stmt::Prefix)
  name = SerdNode(stmt.name, SERD_LITERAL)
  uri = SerdNode(stmt.uri, SERD_URI)
  serd_writer_set_prefix(writer, name, uri)
end

""" Create RDF writer with given IO stream.
"""
function rdf_writer(syntax::String, io::IO)::SerdWriter
  serd_writer_new(serd_syntax(syntax), SerdStyles(0), io)
end

# Constants
###########

# https://www.w3.org/TR/rdf11-concepts/#section-Datatypes
const NS_XSD = "http://www.w3.org/2001/XMLSchema#"
const XSD_BOOLEAN = "$(NS_XSD)boolean"
const XSD_INTEGER = "$(NS_XSD)integer"
const XSD_DECIMAL = "$(NS_XSD)decimal"
const XSD_INT = "$(NS_XSD)int"
const XSD_SHORT = "$(NS_XSD)short"
const XSD_LONG = "$(NS_XSD)long"
const XSD_FLOAT = "$(NS_XSD)float"
const XSD_DOUBLE = "$(NS_XSD)double"

rdf_datatype(::Type{Bool}) = XSD_BOOLEAN
rdf_datatype(::Type{Int16}) = XSD_SHORT
rdf_datatype(::Type{Int32}) = XSD_INT
rdf_datatype(::Type{Int64}) = XSD_INT # XXX: Technically, should be XSD_LONG
rdf_datatype(::Type{Float32}) = XSD_FLOAT
rdf_datatype(::Type{Float64}) = XSD_DOUBLE
rdf_datatype(::Type{T}) where T <: Integer = XSD_INTEGER
rdf_datatype(::Type{T}) where T <: Real = XSD_DECIMAL

const julia_datatypes = Dict{String,Type}(
  XSD_BOOLEAN => Bool,
  XSD_INTEGER => BigInt,
  XSD_DECIMAL => BigFloat,
  XSD_INT => Int, # or Int32, but better to use platform-specific Int type
  XSD_SHORT => Int16,
  XSD_LONG => Int64,
  XSD_FLOAT => Float32,
  XSD_DOUBLE => Float64,
)
julia_datatype(datatype::String) = julia_datatypes[datatype]

const serd_syntaxes = Dict{String,SerdSyntax}(
  "turtle"   => SERD_TURTLE,
  "ntriples" => SERD_NTRIPLES,
  "nquads"   => SERD_NQUADS,
  "trig"     => SERD_TRIG,
)
serd_syntax(syntax::String) = serd_syntaxes[lowercase(syntax)]

# Data types: Julia to C
########################

to_serd(node::ResourceURI) = SerdNode(node.uri, SERD_URI)
to_serd(node::ResourceCURIE) = SerdNode("$(node.prefix):$(node.name)", SERD_CURIE)
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

# Data types: C to Julia
########################

function from_serd(node::SerdNode)::Node
  if node.typ == SERD_URI
    ResourceURI(node.value)
  elseif node.typ == SERD_CURIE
    prefix, name = split(node.value, ':', limit=2)
    ResourceCURIE(prefix, name)
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
