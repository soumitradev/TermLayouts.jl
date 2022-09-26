using Test
using TermLayouts

@testset "core.jl" begin
  @test TermLayouts.wrap("This is a test").content == "This is a test"
  @test TermLayouts.unwrap(TermLayouts.Wrapper("This is a test")) == "This is a test"
end

@testset "core.jl" begin
  @test TermLayouts.read_key(IOBuffer("JuliaLang is a GitHub organization")) == "J"
  @test TermLayouts.read_key(IOBuffer("\x03")) == :EXIT
  @test TermLayouts.read_key(IOBuffer("\e[A")) == "\e[A"
  @test TermLayouts.read_key(IOBuffer("\e[B")) == "\e[B"
  @test TermLayouts.read_key(IOBuffer("\e[C")) == "\e[C"
  @test TermLayouts.read_key(IOBuffer("\e[D")) == "\e[D"
end

@testset "TermLayouts.jl" begin
  @test TermLayouts.loadprefs() == TermLayouts.TermLayoutsPreferences(
    TermLayouts.PanelPrefs(70, "", "", "red"),
    TermLayouts.PanelPrefs(30, "", "", "blue"),
  )
end