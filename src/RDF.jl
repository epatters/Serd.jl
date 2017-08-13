""" Generic Julia interface for RDF graphs.
"""
module RDF
export Node, Statement, BaseURI, Prefix, Resource, Literal, Blank, Triple, Quad

import Base: convert
using AutoHashEquals

# Data types
############

abstract type Node end
abstract type Statement end

@auto_hash_equals struct BaseURI <: Statement
  uri::String
end

@auto_hash_equals struct Prefix <: Statement
  name::String
  uri::String
end

@auto_hash_equals struct Resource <: Node
  uri::String
end

@auto_hash_equals struct Literal <: Node
  value::Any
  language::String
  Literal(value::Any, language::String="") = new(value, language)
end

@auto_hash_equals struct Blank <: Node
  name::String
end

@auto_hash_equals struct Triple <: Statement
  subject::Node
  predicate::Node
  object::Node
end

@auto_hash_equals struct Quad <: Statement
  subject::Node
  predicate::Node
  object::Node
  graph::Node
end

# Convenience constructors
convert(::Type{Node}, x::String) = Resource(x)
convert(::Type{Node}, x::Symbol) = Resource(string(x))

end
