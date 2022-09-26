using Test
using TermLayouts

@testset "core.jl" begin
  @test TermLayouts.wrap("This is a test").content == "This is a test"
  @test TermLayouts.unwrap(TermLayouts.Wrapper("This is a test")) == "This is a test"
end

@testset "io.jl" begin
  @test TermLayouts.read_key(IOBuffer("JuliaLang is a GitHub organization")) == 'J'
  @test TermLayouts.read_key(IOBuffer("\x03")) == :EXIT
  @test TermLayouts.read_key(IOBuffer("\e[A")) == "\e[A"
  @test TermLayouts.read_key(IOBuffer("\e[B")) == "\e[B"
  @test TermLayouts.read_key(IOBuffer("\e[C")) == "\e[C"
  @test TermLayouts.read_key(IOBuffer("\e[D")) == "\e[D"
end

@testset "EditableString" begin
  @testset "enterchar" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'b')
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\e[0mb\e[0m\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.enterchar(string, 'a')
    end
  end

  @testset "entercolor" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.entercolor(string, "\e[32m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.to_string(string, true)
    end == "\e[32ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.entercolor(string, "\e[32m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'b')
      TermLayouts.to_string(string, true)
    end == "\e[32ma\e[0m\e[32mb\e[0m\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.entercolor(string, "\e[0m")
    end
  end

  @testset "cursor_down" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_down(string)
      string.ycursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\n\e[0m \e[0m\e[0ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_up(string)
      TermLayouts.cursor_down(string)
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\n\e[0m \e[0m\e[0ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_right(string)
      TermLayouts.cursor_right(string)
      TermLayouts.cursor_right(string)
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\n\e[0m \e[0m\e[0m \e[0m\e[0m \e[0m\e[0m \e[0m\e[0ma\e[0m\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.cursor_down(string)
    end
  end

  @testset "cursor_left" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_left(string)
      string.xcursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_left(string)
      string.xcursor
    end == 1

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_left(string)
      TermLayouts.enterchar(string, 'b')
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\e[0ma\e[0m\e[0mb\e[0m\e[0ma\e[0m\e[0ma\e[0m\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.xcursor = 8
      TermLayouts.cursor_left(string)
    end
  end

  @testset "cursor_right" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_right(string)
      string.xcursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_right(string)
      string.xcursor
    end == 6

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_right(string)
      TermLayouts.cursor_right(string)
      TermLayouts.cursor_right(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\e[0m \e[0m\e[0m \e[0m\e[0m \e[0m\e[0ma\e[0m\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.xcursor = 8
      TermLayouts.cursor_right(string)
    end
  end

  @testset "cursor_up" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_up(string)
      string.ycursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_up(string)
      string.ycursor
    end == 1

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.cursor_down(string)
      TermLayouts.cursor_down(string)
      TermLayouts.cursor_down(string)
      TermLayouts.cursor_up(string)
      TermLayouts.cursor_up(string)
      string.ycursor
    end == 3

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.cursor_down(string)
    end
  end
end