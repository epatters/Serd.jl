""" Generic Julia interface for RDF graphs.
"""
module RDF
export Node, Resource, Statement, BaseURI, Prefix, ResourceURI, ResourceCURIE,
  Literal, Blank, Triple, Quad, Prefixes

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

# Prefixes
##########

""" Some commonly used RDF prefixes.
"""
module Prefixes
export xsd, rdf, rdfs, owl, skos, dc, foaf, sioc

using ..RDF: Prefix

const xsd = Prefix("xsd", "http://www.w3.org/2001/XMLSchema#")
const rdf = Prefix("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
const rdfs = Prefix("rdfs", "http://www.w3.org/2000/01/rdf-schema#")
const owl = Prefix("owl", "http://www.w3.org/2002/07/owl#")
const skos = Prefix("skos", "http://www.w3.org/2004/02/skos/core#")

const dc = Prefix("dc", "http://purl.org/dc/elements/1.1/")
const foaf = Prefix("foaf", "http://xmlns.com/foaf/0.1/")
const sioc = Prefix("sioc", "http://rdfs.org/sioc/ns#")

end

end
