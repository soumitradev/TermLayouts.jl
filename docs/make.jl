using Documenter, TermLayouts

makedocs(sitename="TermLayouts.jl", modules=Module[TermLayouts])
deploydocs(
  repo="github.com/soumitradev/TermLayouts.jl.git",
)