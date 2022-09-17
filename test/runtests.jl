using Test
using TermLayouts

@test TermLayouts.wrap("This is a test").content == "This is a test"
