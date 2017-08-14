""" Low-level wrapper of C library Serd.
"""
module CSerd
export SerdException, SerdNode, SerdStatement, SerdStatementFlags, SerdStyles,
  SerdReader, serd_reader_new, serd_reader_free,
  serd_reader_set_error_sink, serd_reader_set_strict,
  serd_reader_add_blank_prefix, serd_reader_set_default_graph,
  serd_reader_read_file, serd_reader_read_string,
  SerdWriter, serd_writer_new, serd_writer_write_statement, serd_writer_finish,
  serd_writer_free
  
# Reference to Serd library.
include("../deps/deps.jl")

import Base: convert
using AutoHashEquals

""" Export an enum and all its values.
"""
macro export_enum(name::Symbol)
  expr = :(eval(Expr(:export, $(QuoteNode(name)), 
                     (Symbol(inst) for inst in instances($name))...)))
  esc(Expr(:toplevel, expr))
end

const Cbool = UInt8

# Data types
############

@enum(SerdStatus,
  SERD_SUCCESS,
  SERD_FAILURE,
  SERD_ERR_UNKNOWN,
  SERD_ERR_BAD_SYNTAX,
  SERD_ERR_BAD_ARG,
  SERD_ERR_NOT_FOUND,
  SERD_ERR_ID_CLASH,
  SERD_ERR_BAD_CURIE,
  SERD_ERR_INTERNAL)
@export_enum SerdStatus

@enum(SerdSyntax,
  SERD_TURTLE   = 1,  # Turtle - Terse RDF Triple Language
  SERD_NTRIPLES = 2,  # NTriples - Line-based RDF triples
  SERD_NQUADS   = 3,  # NQuads - Line-based RDF quads
  SERD_TRIG     = 4)  # TRiG - Terse RDF quads
@export_enum SerdSyntax

@enum(SerdStatementFlag,
  SERD_EMPTY_S      = 1 << 1,  # Empty blank node subject
  SERD_EMPTY_O      = 1 << 2,  # Empty blank node object
  SERD_ANON_S_BEGIN = 1 << 3,  # Start of anonymous subject
  SERD_ANON_O_BEGIN = 1 << 4,  # Start of anonymous object
  SERD_ANON_CONT    = 1 << 5,  # Continuation of anonymous node
  SERD_LIST_S_BEGIN = 1 << 6,  # Start of list subject
  SERD_LIST_O_BEGIN = 1 << 7,  # Start of list object
  SERD_LIST_CONT    = 1 << 8)  # Continuation of list
@export_enum SerdStatementFlag
const SerdStatementFlags = UInt32

@enum(SerdType,
  SERD_NOTHING = 0,  # The type of a nonexistent node.
  SERD_LITERAL = 1,  # Literal value
  SERD_URI     = 2,  # URI (absolute or relative)
  SERD_CURIE   = 3,  # CURIE, a shortened URI
  SERD_BLANK   = 4)  # A blank node
@export_enum SerdType

@enum(SerdStyle,
  SERD_STYLE_ABBREVIATED = 1,       # Abbreviate triples when possible
  SERD_STYLE_ASCII       = 1 << 1,  # Escape all non-ASCII characters
  SERD_STYLE_RESOLVED    = 1 << 2,  # Resolve URIs against base URI
  SERD_STYLE_CURIED      = 1 << 3,  # Shorten URIs into CURIEs
  SERD_STYLE_BULK        = 1 << 4)  # Write output in pages
@export_enum SerdStyle
const SerdStyles = UInt32

struct SerdException <: Exception
  status::SerdStatus
end

@auto_hash_equals struct SerdNode
  value::String
  typ::SerdType
end

@auto_hash_equals struct SerdStatement
  flags::SerdStatementFlags
  graph::Nullable{SerdNode}
  subject::SerdNode
  predicate::SerdNode
  object::SerdNode
  object_datatype::Nullable{SerdNode}
  object_lang::Nullable{SerdNode}
end

mutable struct SerdReader
  ptr::Ptr{Void}
end

mutable struct SerdWriter
  ptr::Ptr{Void}
  env::Ptr{Void}
end

struct CSerdNode
  buf::Ptr{UInt8}
  n_bytes::Csize_t
  n_chars::Csize_t
  flags::Cint
  typ::Cint
end

struct CSerdError
  status::Cint
  filename::Ptr{UInt8}
  line::Cuint
  col::Cuint
  char::Ptr{Cchar}
  args::Ptr{Void} # va_list *
end

# Node
######

""" Convert Serd node from Julia struct to C struct.
"""
function c_serd_node(node::SerdNode)::CSerdNode
  ccall((:serd_node_from_string, serd), CSerdNode, (Cint, Cstring),
        Cint(node.typ), node.value)
end
function c_serd_node(node::Nullable{SerdNode})::Ptr{CSerdNode}
  isnull(node) ?
    C_NULL : Base.unsafe_convert(Ptr{CSerdNode}, c_serd_node(get(node)))
end

""" Convert Serd node from C struct to Julia struct.
"""
function unsafe_serd_node(ptr::Ptr{CSerdNode})::Nullable{SerdNode}
  if ptr == C_NULL
    Nullable{SerdNode}()
  else
    typ = unsafe_load(Ptr{Cint}(ptr + fieldoffset(CSerdNode,5)))
    if typ == SERD_NOTHING
      Nullable{SerdNode}()
    else
      n_bytes = unsafe_load(Ptr{Csize_t}(ptr + fieldoffset(CSerdNode,2)))
      value_ptr = unsafe_load(Ptr{Ptr{UInt8}}(ptr))
      value = unsafe_string(value_ptr, n_bytes)
      Nullable(SerdNode(value, SerdType(typ)))
    end
  end
end

serd_status(status) = Cint(isa(status, SerdStatus) ? status : SERD_SUCCESS)

function check_status(status)
  status = SerdStatus(status)
  if status != SERD_SUCCESS
    throw(SerdException(status))
  end
end

# Reader
########

""" Create a new RDF reader.
"""
function serd_reader_new(syntax::SerdSyntax, base_sink, prefix_sink,
                         statement_sink, end_sink)::SerdReader

  function serd_base_sink(handle::Ptr{Void}, uri::Ptr{CSerdNode})
    serd_status(base_sink(get(unsafe_serd_node(uri))))
  end
  serd_base_sink_ptr = base_sink == nothing ? C_NULL :
    cfunction(serd_base_sink, Cint, (Ptr{Void}, Ptr{CSerdNode}))
  
  function serd_prefix_sink(handle::Ptr{Void}, name::Ptr{CSerdNode}, uri::Ptr{CSerdNode})
    serd_status(prefix_sink(
      get(unsafe_serd_node(name)),
      get(unsafe_serd_node(uri))
    ))
  end
  serd_prefix_sink_ptr = prefix_sink == nothing ? C_NULL :
    cfunction(serd_prefix_sink, Cint, (Ptr{Void}, Ptr{CSerdNode}, Ptr{CSerdNode}))
  
  function serd_statement_sink(
      handle::Ptr{Void}, flags::Cint, graph::Ptr{CSerdNode},
      subject::Ptr{CSerdNode}, predicate::Ptr{CSerdNode}, object::Ptr{CSerdNode},
      object_datatype::Ptr{CSerdNode}, object_lang::Ptr{CSerdNode}
    )
    serd_status(statement_sink(SerdStatement(
      flags,
      unsafe_serd_node(graph),
      get(unsafe_serd_node(subject)),
      get(unsafe_serd_node(predicate)),
      get(unsafe_serd_node(object)),
      unsafe_serd_node(object_datatype),
      unsafe_serd_node(object_lang),
    )))
  end
  serd_statement_sink_ptr = statement_sink == nothing ? C_NULL : 
    cfunction(
      serd_statement_sink,
      Cint,
      (Ptr{Void}, Cint, Ptr{CSerdNode}, Ptr{CSerdNode}, Ptr{CSerdNode},
       Ptr{CSerdNode}, Ptr{CSerdNode}, Ptr{CSerdNode})
    )
  
  function serd_end_sink(handle::Ptr{Void}, node::Ptr{CSerdNode})
    serd_status(end_sink(get(unsafe_serd_node(node))))
  end
  serd_end_sink_ptr = end_sink == nothing ? C_NULL :
    cfunction(serd_end_sink, Cint, (Ptr{Void}, Ptr{CSerdNode}))
  
  reader_ptr = ccall(
    (:serd_reader_new, serd),
    Ptr{Void},
    (Cint, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}),
    syntax, C_NULL, C_NULL, serd_base_sink_ptr, serd_prefix_sink_ptr,
    serd_statement_sink_ptr, serd_end_sink_ptr)
  reader = SerdReader(reader_ptr)
  finalizer(reader, serd_reader_free)
  return reader
end

""" Set a function to be called when errors occur during reading.

If no error function is set, errors are printed to stderr in GCC style.
"""
function serd_reader_set_error_sink(reader::SerdReader, error_sink)
  function serd_error_sink(handle::Ptr{Void}, error::Ptr{CSerdError})
    # FIXME: Include error information besides status code.
    status = unsafe_load(Ptr{Cint}(ptr))
    serd_status(error_sink(status))
  end
  serd_error_sink_ptr = cfunction(serd_error_sink, Cint, (Ptr{Void}, Ptr{CSerdError}))
  
  ccall(
    (:serd_reader_set_error_sink, serd),
    Void,
    (Ptr{Void}, Ptr{Void}),
    reader.ptr, serd_error_sink_ptr)
end

""" Enable or disable strict parsing.

The reader is non-strict (lax) by default, which will tolerate URIs with
invalid characters. Setting strict will fail when parsing such files. An error
is printed for invalid input in either case.
"""
function serd_reader_set_strict(reader::SerdReader, strict::Bool)
  ccall((:serd_reader_set_strict, serd), Void, (Ptr{Void}, Cbool),
        reader.ptr, strict)
end

""" Set a prefix to be added to all blank node identifiers.

This is useful when multiple files are to be parsed into the same output
(e.g. a store, or other files). Since Serd preserves blank node IDs, this could
cause conflicts where two non-equivalent blank nodes are merged, resulting in
corrupt data. By setting a unique blank node prefix for each parsed file, this
can be avoided, while preserving blank node names.
"""
function serd_reader_add_blank_prefix(reader::SerdReader, prefix::String)
  ccall((:serd_reader_add_blank_prefix, serd), Void, (Ptr{Void}, Cstring),
        reader.ptr, prefix)
end

""" Set the URI of the default graph.

If this is set, the reader will emit quads with the graph set to the given node
for any statements that are not in a named graph.
"""
function serd_reader_set_default_graph(reader::SerdReader, graph::SerdNode)
  ccall((:serd_reader_set_default_graph, serd), Void, (Ptr{Void}, Ref{CSerdNode}),
        reader.ptr, c_serd_node(graph))
end

""" Read a file at a given URI.
"""
function serd_reader_read_file(reader::SerdReader, uri::String)
  check_status(ccall(
    (:serd_reader_read_file, serd),
    Cint,
    (Ptr{Void}, Cstring),
    reader.ptr, uri
  ))
end

""" Read from UTF8 string.
"""
function serd_reader_read_string(reader::SerdReader, str::String)
  check_status(ccall(
    (:serd_reader_read_string, serd),
    Cint,
    (Ptr{Void}, Cstring),
    reader.ptr, str
  ))
end

""" Free RDF reader. 

This function will be called automatically when the Julia Serd reader is
garbage collected.
"""
function serd_reader_free(reader::SerdReader)
  if reader.ptr != C_NULL
    ccall((:serd_reader_free, serd), Void, (Ptr{Void},), reader.ptr)
    reader.ptr = C_NULL
  end
end

# Writer
########

""" Create a new RDF writer.
"""
function serd_writer_new(syntax::SerdSyntax, style::SerdStyles, sink)::SerdWriter
  function serd_sink(buf::Ptr{Void}, len::Csize_t, stream::Ptr{Void})
    sink(unsafe_string(Ptr{UInt8}(buf), len))
    return len
  end
  serd_sink_ptr = cfunction(serd_sink, Csize_t, (Ptr{Void}, Csize_t, Ptr{Void}))
  
  env_ptr = ccall((:serd_env_new, serd), Ptr{Void}, (Ptr{CSerdNode},), C_NULL)
  writer_ptr = ccall(
    (:serd_writer_new, serd),
    Ptr{Void},
    (Cint, Cint, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}),
    syntax, style, env_ptr, C_NULL, serd_sink_ptr, C_NULL)
  writer = SerdWriter(writer_ptr, env_ptr)
  finalizer(writer, serd_writer_finalize)
  return writer
end
function serd_writer_finalize(writer)
  serd_writer_finish(writer)
  serd_writer_free(writer)
end

""" Write a statement (RDF triple or quad).
"""
function serd_writer_write_statement(writer::SerdWriter, stmt::SerdStatement)
  serd_status(ccall(
    (:serd_writer_write_statement, serd),
    Cint,
    (Ptr{Void}, Cint, Ptr{CSerdNode}, Ref{CSerdNode}, Ref{CSerdNode},
     Ref{CSerdNode}, Ptr{CSerdNode}, Ptr{CSerdNode}),
    writer.ptr,
    stmt.flags,
    c_serd_node(stmt.graph),
    c_serd_node(stmt.subject),
    c_serd_node(stmt.predicate),
    c_serd_node(stmt.object),
    c_serd_node(stmt.object_datatype),
    c_serd_node(stmt.object_lang)
  ))
end

""" Finish a write.

This function will be called automatically when the Julia Serd writer is
garbage collected.
"""
function serd_writer_finish(writer::SerdWriter)
  if writer.ptr != C_NULL
    ccall((:serd_writer_finish, serd), Void, (Ptr{Void},), writer.ptr)
  end
end

""" Free RDF writer. 

This function will be called automatically when the Julia Serd writer is
garbage collected.
"""
function serd_writer_free(writer::SerdWriter)
  if writer.ptr != C_NULL
    ccall((:serd_writer_free, serd), Void, (Ptr{Void},), writer.ptr)
    writer.ptr = C_NULL
  end
  if writer.env != C_NULL
    ccall((:serd_env_free, serd), Void, (Ptr{Void},), writer.env)
    writer.env = C_NULL
  end
end

end
