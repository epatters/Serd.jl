""" Generic Julia interface for RDF graphs.
"""
module RDF
export Expression, Statement, Node, Edge, BaseURI, Prefix,
  Resource, ResourceURI, ResourceCURIE, Literal, Blank, Triple, Quad

using AutoHashEquals
using Nullables

# Data types
############

abstract type Expression end
abstract type Statement <: Expression end

@auto_hash_equals struct BaseURI <: Statement
  uri::String
end

@auto_hash_equals struct Prefix <: Statement
  name::String
  uri::String
end

abstract type Node <: Expression end
abstract type Resource <: Node end

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

abstract type Edge <: Statement end

@auto_hash_equals struct Triple <: Edge
  subject::Union{Resource,Blank}
  predicate::Resource
  object::Node
end

@auto_hash_equals struct Quad <: Edge
  subject::Union{Resource,Blank}
  predicate::Resource
  object::Node
  graph::Resource
end

# Convenience constructors
Prefix(name::String) = Prefixes.prefix(name)
Resource(uri::String) = ResourceURI(uri)
Resource(prefix::String, name::String) = ResourceCURIE(prefix, name)

Edge(subj::Node, pred::Node, obj::Node) = Triple(subj, pred, obj)
Edge(subj::Node, pred::Node, obj::Node, graph::Node) = Quad(subj, pred, obj, graph)
Edge(subj::Node, pred::Node, obj::Node, graph::Nothing) = Triple(subj, pred, obj)

function Edge(subj::Node, pred::Node, obj::Node, graph::Nullable{<:Node})
  isnull(graph) ? Triple(subj, pred, obj) : Quad(subj, pred, obj, get(graph))
end

# Prefixes
##########

module Prefixes
export prefix, add_prefix!

using ..RDF: Prefix

const _prefixes = Dict{String,Prefix}()

function prefix(name::String)::Prefix
  _prefixes[name]
end

function add_prefix!(name::String, uri::String)
  if haskey(_prefixes, name)
    error("Prefix \"$name\" already defined")
  end
  _prefixes[name] = Prefix(name, uri)
end

add_prefix!("xsd", "http://www.w3.org/2001/XMLSchema#")
add_prefix!("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
add_prefix!("rdfs", "http://www.w3.org/2000/01/rdf-schema#")
add_prefix!("owl", "http://www.w3.org/2002/07/owl#")

add_prefix!("schema", "http://schema.org/")
add_prefix!("skos", "http://www.w3.org/2004/02/skos/core#")
add_prefix!("prov", "http://www.w3.org/ns/prov#")

end

end
