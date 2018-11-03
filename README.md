# Serd.jl

[![Build Status](https://travis-ci.org/epatters/Serd.jl.svg?branch=master)](https://travis-ci.org/epatters/Serd.jl)

This package provides Julia bindings to [Serd](https://drobilla.net/software/serd),
a C library for serializing [RDF](http://www.w3.org/TR/rdf11-primer/) data in 
the [Turtle](https://www.w3.org/TeamSubmission/turtle/), 
[TriG](https://www.w3.org/TR/trig/),
[N-Triples](https://www.w3.org/TR/n-triples/), and
[N-Quads](https://www.w3.org/TR/n-quads/) formats. The main module `Serd`
provides a high-level interface for reading and writing RDF, while the submodule
`Serd.CSerd` is a thin wrapper around Serd's C API.
