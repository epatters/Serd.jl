using BinDeps
@BinDeps.setup

serd = library_dependency("serd", aliases=["libserd", "libserd-0"])

if Sys.isapple()
  using Homebrew
  provides(Homebrew.HB, "serd", serd, os=:Darwin)
end

@BinDeps.install Dict(:serd => :serd)
