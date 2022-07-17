mutable struct ColoredChar
  char::Char
  color::String
end

mutable struct EditableString
  strings::Array{Array{ColoredChar}}
  xcursor::Unsigned
  ycursor::Unsigned
  current_color::String
end

function enterchar(str::EditableString, char::Char)
  if str.ycursor == 0
    str.strings = insert!(str.strings, 1, [ColoredChar(char, str.current_color)])
    str.ycursor = 1
    str.xcursor = 2
  elseif 0 < str.ycursor <= length(str.strings)
    str.strings[str.ycursor] = insert!(str.strings[str.ycursor], str.xcursor, ColoredChar(char, str.current_color))
    str.xcursor += 1
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function entercolor(str::EditableString, color::String)
  if 0 <= str.ycursor <= length(str.strings)
    str.current_color = color
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_down(str::EditableString)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    if 0 < str.ycursor < length(str.strings)
      str.ycursor += 1
    else
      str.ycursor += 1
      str.strings = insert!(str.strings, str.ycursor, [])
    end
    if str.xcursor > length(str.strings[str.ycursor]) + 1
      str.strings[str.ycursor] = append!(str.strings[str.ycursor], [ColoredChar(' ', str.current_color) for _ in 1:(str.xcursor-length(str.strings[str.ycursor])-1)])
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_left(str::EditableString)
  if str.xcursor == 0 || str.xcursor == 1
    return
  elseif 1 < str.xcursor <= length(str.strings[str.ycursor]) + 1
    str.xcursor -= 1
  else
    throw(BoundsError(str.strings[str.ycursor], str.xcursor))
  end
end

function cursor_right(str::EditableString)
  if str.xcursor == 0
    return
  elseif 0 < str.xcursor < length(str.strings[str.ycursor]) + 1
    str.xcursor += 1
  elseif str.xcursor == length(str.strings[str.ycursor]) + 1
    push!(str.strings[str.ycursor], ColoredChar(' ', str.current_color))
    str.xcursor += 1
  else
    throw(BoundsError(str.strings[str.ycursor], str.xcursor))
  end
end

function cursor_up(str::EditableString)
  if str.ycursor == 0 || str.ycursor == length(str.strings)
    return
  elseif 1 < str.ycursor <= length(str.strings)
    str.ycursor -= 1
    if str.xcursor > length(str.strings[str.ycursor]) + 1
      str.strings[str.ycursor] = append!(str.strings[str.ycursor], [ColoredChar(' ', str.current_color) for _ in 1:(str.xcursor-length(str.strings[str.ycursor])-1)])
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function carriage_return(str::EditableString)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    str.xcursor = 1
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_next_line(str::EditableString)
  if str.ycursor == 0 || str.ycursor == length(str.strings)
    return
  elseif 0 < str.ycursor < length(str.strings)
    str.ycursor += 1
    carriage_return(str)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_prev_line(str::EditableString)
  if str.ycursor == 0 || str.ycursor == length(str.strings)
    return
  elseif 1 < str.ycursor <= length(str.strings)
    str.ycursor -= 1
    carriage_return(str)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_horizontal_absolute(str::EditableString, x::Int)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    str.xcursor = x
    if x > length(str.strings[str.ycursor]) + 1
      str.strings[str.ycursor] = append!(str.strings[str.ycursor], [ColoredChar(' ', str.current_color) for _ in 1:(x-(length(str.strings[str.ycursor])+1))])
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_position(str::EditableString, x::Int, y::Int)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    str.ycursor = y
    if y > length(str.strings)
      str.strings = append!(str.strings, [[] for _ in length(str.strings):(y-1)])
    end
    cursor_horizontal_absolute(str, x)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function erase_in_display(str::EditableString, n::Int)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    if n == 0
      str.strings[str.ycursor] = append!(str.strings[str.ycursor][1:str.xcursor-1], [ColoredChar(' ', str.current_color) for i in 1:((length(str.strings[str.ycursor])+1)-str.xcursor)])
      for i in str.ycursor+1:length(str.strings)
        str.strings[i] = [ColoredChar(' ', str.current_color) for _ in 1:length(str.strings[i])]
      end
    elseif n == 1
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (' '^((length(str.strings[str.ycursor]) + 1) - str.xcursor))
      for i in 1:str.ycursor-1
        str.strings[i] = [ColoredChar(' ', str.current_color) for _ in 1:length(str.strings[i])]
      end
    elseif n == 2 || n == 3
      for i in 1:length(str.strings)
        str.strings[i] = [ColoredChar(' ', str.current_color) for _ in 1:length(str.strings[i])]
      end
    else
      throw(ArgumentError("n can't be above 3"))
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function erase_in_line(str::EditableString, n::Int)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    if n == 0
      str.strings[str.ycursor] = append!(str.strings[str.ycursor][1:str.xcursor-1], [ColoredChar(' ', str.current_color) for _ in 1:((length(str.strings[str.ycursor])+1)-str.xcursor)])
    elseif n == 1
      str.strings[str.ycursor] = append!(str.strings[str.ycursor][1:str.xcursor-1], [ColoredChar(' ', str.current_color) for _ in 1:((length(str.strings[str.ycursor])+1)-str.xcursor)])
    elseif n == 2
      str.strings[str.ycursor] = [ColoredChar(' ', str.current_color) for _ in 1:length(str.strings[str.ycursor])]
    else
      throw(ArgumentError("n can't be above 3"))
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function scroll_up(str::EditableString, n::Int)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    str.strings = append!(str.strings, [[] for _ in 1:n])
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function scroll_down(str::EditableString, n::Int)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
    str.strings = append!([[] for _ in 1:n], str.strings)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function newline(str::EditableString)
  if str.ycursor == 0
    str.strings = append!([[], []], str.strings)
    str.ycursor += 2
    str.xcursor = 1
  elseif 0 < str.ycursor <= length(str.strings)
    str.strings = insert!(str.strings, str.ycursor + 1, str.strings[str.ycursor][str.xcursor:end])
    str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1]
    str.ycursor += 1
    str.xcursor = 1
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function to_string(str::EditableString)
  builtstring = ""
  color = ""
  for line in str.strings
    for char in line
      if char.color != color
        builtstring *= char.color
        color = char.color
      end
      builtstring *= string(char.char)
    end
    builtstring *= "\n"
  end
  return builtstring
end

function parseANSI(console::EditableString, str::String)
  cur = 1
  while cur <= length(str)
    if str[cur] == '\r'
      carriage_return(console)
    elseif str[cur] == '\n'
      newline(console)
    elseif str[cur] == '\e'
      if (str[cur+1]) == '['
        cur += 2
        n = ""
        while isdigit(str[cur])
          n *= str[cur]
          cur += 1
        end
        number = length(n) > 0 ? parse(Int, n) : 0
        if str[cur] == 'A'
          for _ in 1:number
            cursor_up(console)
          end
        elseif str[cur] == 'B'
          for _ in 1:number
            cursor_down(console)
          end
        elseif str[cur] == 'C'
          for _ in 1:number
            cursor_right(console)
          end
        elseif str[cur] == 'D'
          for _ in 1:number
            cursor_left(console)
          end
        elseif str[cur] == 'E'
          for _ in 1:number
            cursor_next_line(console)
          end
        elseif str[cur] == 'F'
          for _ in 1:number
            cursor_prev_line(console)
          end
        elseif str[cur] == 'G'
          cursor_horizontal_absolute(console, number)
        elseif str[cur] == ';'
          cur += 1
          m = ""
          while isdigit(str[cur])
            m *= str[cur]
            cur += 1
          end
          mumber = length(m) > 0 ? parse(Int, m) : 0
          if str[cur] == 'H'
            cursor_position(console, number, mumber)
          else
            enterchar(console, '\e')
            enterchar(console, '[')
            for c in n
              enterchar(console, c)
            end
            enterchar(console, ';')
            for d in m
              enterchar(console, d)
            end
            enterchar(console, str[cur])
          end
        elseif str[cur] == 'J'
          erase_in_display(console, number)
        elseif str[cur] == 'K'
          erase_in_line(console, number)
        elseif str[cur] == 'S'
          scroll_up(console, number)
        elseif str[cur] == 'T'
          scroll_down(console, number)
        elseif str[cur] == 'm'
          entercolor(console, "\e[" * string(number) * "m")
        elseif str[cur] == '?'
          cur += 1
          m = ""
          while isdigit(str[cur])
            m *= str[cur]
            cur += 1
          end
          mumber = length(m) > 0 ? parse(Int, m) : 0
          if str[cur] == 'l' || str[cur] == 'h'
          else
            enterchar(console, '\e')
            enterchar(console, '[')
            for c in n
              enterchar(console, c)
            end
            enterchar(console, '?')
            for d in m
              enterchar(console, d)
            end
            enterchar(console, str[cur])
          end
        else
          enterchar(console, '\e')
          enterchar(console, '[')
          for c in n
            enterchar(console, c)
          end
          enterchar(console, str[cur])
        end
      else
        enterchar(console, str[cur])
      end
    else
      enterchar(console, str[cur])
    end
    cur += 1
  end
  return to_string(console)
end