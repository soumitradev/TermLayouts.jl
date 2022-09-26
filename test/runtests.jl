using Test
using TermLayouts

@testset "core.jl" begin
  @test TermLayouts.wrap("This is a test").content == "This is a test"
  @test TermLayouts.unwrap(TermLayouts.Wrapper("This is a test")) == "This is a test"
  @test TermLayouts.start_eval_backend(TermLayouts.TermLayoutsState()) isa Task
end

@testset "io.jl" begin
  @test TermLayouts.read_key(IOBuffer("JuliaLang is a GitHub organization")) == 'J'
  @test TermLayouts.read_key(IOBuffer("\x03")) == :EXIT
  @test TermLayouts.read_key(IOBuffer("\e[A")) == "\e[A"
  @test TermLayouts.read_key(IOBuffer("\e[B")) == "\e[B"
  @test TermLayouts.read_key(IOBuffer("\e[C")) == "\e[C"
  @test TermLayouts.read_key(IOBuffer("\e[D")) == "\e[D"
end

@testset "errors.jl" begin
  @test TermLayouts.EvalError("This is a test", "nothing") isa TermLayouts.EvalError
  @test TermLayouts.EvalErrorStack("This is a test") isa TermLayouts.EvalErrorStack
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
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_right(string)
      string.xcursor
    end == 4

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

  @testset "carriage_return" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.carriage_return(string)
      string.ycursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.carriage_return(string)
      string.xcursor
    end == 1

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.carriage_return(string)
    end
  end

  @testset "cursor_next_line" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_next_line(string)
      string.ycursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_next_line(string)
      string.ycursor
    end == 1

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_up(string)
      TermLayouts.cursor_next_line(string)
      string.ycursor
    end == 3

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.cursor_next_line(string)
    end
  end

  @testset "cursor_prev_line" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_prev_line(string)
      string.ycursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_prev_line(string)
      string.ycursor
    end == 1

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_prev_line(string)
      string.ycursor
    end == 1

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.cursor_prev_line(string)
    end
  end

  @testset "cursor_horizontal_absolute" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_horizontal_absolute(string, 10)
      string.xcursor
    end == 0

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_horizontal_absolute(string, 3)
      string.xcursor
    end == 3

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_horizontal_absolute(string, 5)
      string.xcursor
    end == 5

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.cursor_horizontal_absolute(string, 5)
    end
  end

  @testset "cursor_position" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.cursor_position(string, 10, 10)
      string.xcursor, string.ycursor
    end == (0, 0)

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_down(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_position(string, 2, 2)
      string.xcursor, string.ycursor
    end == (2, 2)

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_position(string, 5, 5)
      string.xcursor, string.ycursor
    end == (5, 5)

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.cursor_position(string, 5, 5)
    end
  end

  @testset "erase_in_display" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.erase_in_display(string, 0)
      string.xcursor, string.ycursor
    end == (0, 0)

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_position(string, 2, 2)
      TermLayouts.erase_in_display(string, 0)
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\e[0ma\e[0m\e[0ma\e[0m\n\e[0ma\e[0m\n\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_position(string, 2, 2)
      TermLayouts.erase_in_display(string, 1)
      TermLayouts.to_string(string, true)
    end == "\n\e[0m \e[0m\e[0m \e[0m\e[0ma\e[0m\n\e[0ma\e[0m\e[0ma\e[0m\e[0ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_position(string, 2, 2)
      TermLayouts.erase_in_display(string, 2)
      TermLayouts.to_string(string, true)
    end == "\n\n\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_position(string, 2, 2)
      TermLayouts.erase_in_display(string, 3)
      TermLayouts.to_string(string, true)
    end == "\n\n\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.erase_in_display(string, 0)
    end
  end

  @testset "erase_in_line" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.erase_in_line(string, 0)
      string.xcursor, string.ycursor
    end == (0, 0)

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_horizontal_absolute(string, 3)
      TermLayouts.erase_in_line(string, 0)
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\e[0ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_horizontal_absolute(string, 3)
      TermLayouts.erase_in_line(string, 1)
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\e[0ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_horizontal_absolute(string, 3)
      TermLayouts.erase_in_line(string, 2)
      TermLayouts.to_string(string, true)
    end == "\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.erase_in_display(string, 0)
    end
  end

  @testset "scroll_up" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.scroll_up(string, 0)
      string.xcursor, string.ycursor
    end == (0, 0)

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.scroll_up(string, 3)
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\n\e[0ma\e[0m\n\e[0ma\e[0m\n\e[0ma\e[0m\n\e[0ma\e[0m\n\n\n\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.scroll_up(string, 0)
    end
  end

  @testset "scroll_down" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.scroll_down(string, 0)
      string.xcursor, string.ycursor
    end == (0, 0)

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.newline(string)
      TermLayouts.enterchar(string, 'a')
      TermLayouts.scroll_down(string, 3)
      TermLayouts.to_string(string, true)
    end == "\n\n\n\e[0ma\e[0m\n\e[0ma\e[0m\n\e[0ma\e[0m\n\e[0ma\e[0m\n\e[0ma\e[0m\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.scroll_down(string, 0)
    end
  end

  @testset "newline" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.newline(string)
      TermLayouts.to_string(string, true)
    end == "\n\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.enterchar(string, 'a')
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_left(string)
      TermLayouts.cursor_left(string)
      TermLayouts.newline(string)
      TermLayouts.to_string(string, true)
    end == "\e[0ma\e[0m\e[0ma\e[0m\n\e[0ma\e[0m\e[0ma\e[0m\e[0ma\e[0m\n"

    @test_throws BoundsError begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      string.ycursor = 8
      TermLayouts.newline(string)
    end
  end

  @testset "to_string" begin
    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.entercolor(string, "\e[32m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.entercolor(string, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.entercolor(string, "\e[12m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.to_string(string, true)
    end == "\e[32ma\e[0m\e[0ma\e[0m\e[12ma\e[0m\n"

    @test begin
      string = TermLayouts.EditableString([], 0, 0, "\e[0m")
      TermLayouts.entercolor(string, "\e[32m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.entercolor(string, "\e[0m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.entercolor(string, "\e[12m")
      TermLayouts.enterchar(string, 'a')
      TermLayouts.to_string(string, false)
    end == "aaa\n"

    @test begin
      string = TermLayouts.EditableString([[TermLayouts.ColoredChar(' ', "\e[0m", true), TermLayouts.ColoredChar(' ', "\e[0m", true), TermLayouts.ColoredChar(' ', "\e[0m", true), TermLayouts.ColoredChar('t', "\e[0m", false)]], 5, 1, "\e[0m")
      TermLayouts.to_string(string, false)
    end == "t\n"
  end

  @testset "simplifyANSI" begin
    @test begin
      string = TermLayouts.simplifyANSI("abce\nefgh\raqcd\e[1A\e[1Dd\r\e[1C\e[1Bb\e[1;1H\e[1E\e[1F\n\e[5Ge\nabcdefg\e[4G\e[0J\e[0K\e[1S\e[1T\e[32mjulia>\e[0m\e[?2004h\e[?2004l\e[Z\eZZ", true)
    end == "\n\n\e[0ma\e[0m\e[0mb\e[0m\e[0mc\e[0m\e[32mj\e[0m\e[32mu\e[0m\e[32ml\e[0m\e[32mi\e[0m\e[32ma\e[0m\e[32m>\e[0m\e[0m\e\e[0m\e[0m[\e[0m\e[0mZ\e[0m\e[0m\e\e[0m\e[0mZ\e[0m\e[0mZ\e[0m\e[0md\e[0m\e[0me\e[0m\n\e[0ma\e[0m\e[0mb\e[0m\e[0mc\e[0m\n\n\n"
  end
end

@testset "TermLayouts.jl" begin
  @test TermLayouts.loadprefs() isa TermLayouts.TermLayoutsPreferences
end