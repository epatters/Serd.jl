using Test

include("./data/turtle_ex1.jl")

@testset "CSerd" begin
  include("CSerd.jl")
end

@testset "Serd" begin
  include("Serd.jl")
end
