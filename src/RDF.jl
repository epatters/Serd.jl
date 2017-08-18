""" Generic Julia interface for RDF graphs.
"""
module RDF
export Node, Resource, Statement, BaseURI, Prefix, ResourceURI, ResourceCURIE,
  Literal, Blank, Triple, Quad

using AutoHashEquals

# Data types
############

abstract type Node end
abstract type Resource <: Node end
abstract type Statement end

@auto_hash_equals struct BaseURI <: Statement
  uri::String
end

@auto_hash_equals struct Prefix <: Statement
  name::String
  uri::String
end

@auto_hash_equals struct ResourceURI <: Resource
  uri::String
end

@auto_hash_equals struct ResourceCURIE <: Resource
  prefix::String
  name::String
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
Resource(uri::String) = ResourceURI(uri)
Resource(prefix::String, name::String) = ResourceCURIE(prefix, name)

end
