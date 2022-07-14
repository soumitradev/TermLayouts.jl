mutable struct EditableString
  strings::Array{String}
  xcursor::Unsigned
  ycursor::Unsigned
  function EditableString()
    self.strings = []
    self.xcursor = 0
    self.ycursor = 0
  end
end

function enterchar(str::EditableString, char::Char)
  if str.ycursor == 0
    str.strings = insert!(str.strings, 1, string(char))
    str.ycursor = 1
    str.xcursor = 2
  elseif 0 < str.ycursor <= len(str.strings)
    stringAtY = collect(str.strings[str.ycursor])
    stringAtY = insert!(stringAtY, str.xcursor, char)
    str.strings[str.ycursor] = join(stringAtY)
    str.xcursor += 1
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_down(str::EditableString)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)

    if 0 < str.ycursor < len(str.strings)
      str.ycursor += 1
    else
      str.ycursor += 1
      str.strings = insert!(str.strings, str.ycursor, "")
    end

    if str.xcursor > len(str.strings[str.ycursor]) + 1
      str.strings[str.ycursor] = str.strings[str.ycursor] * (" "^(str.xcursor - len(str.strings[str.ycursor]) - 1))
    end

  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_left(str::EditableString)
  if str.xcursor == 0 || str.xcursor == 1
    return
  elseif 1 < str.xcursor <= len(str.strings[str.ycursor]) + 1
    str.xcursor -= 1
  else
    throw(BoundsError(str.strings[str.ycursor], str.xcursor))
  end
end

function cursor_right(str::EditableString)
  if str.xcursor == 0
    return
  elseif 0 < str.xcursor < len(str.strings[str.ycursor]) + 1
    str.xcursor += 1
  elseif str.xcursor == len(str.strings[str.ycursor]) + 1
    str.strings[str.ycursor] *= " "
    str.xcursor += 1
  else
    throw(BoundsError(str.strings[str.ycursor], str.xcursor))
  end
end

function cursor_up(str::EditableString)
  if str.ycursor == 0 || str.ycursor == len(str.strings)
    return
  elseif 1 < str.ycursor <= len(str.strings)
    str.ycursor -= 1
    if str.xcursor > len(str.strings[str.ycursor]) + 1
      str.strings[str.ycursor] = str.strings[str.ycursor] * (" "^(str.xcursor - len(str.strings[str.ycursor]) - 1))
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function carriage_return(str::EditableString)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)
    str.xcursor = 1
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_next_line(str::EditableString)
  if str.ycursor == 0 || str.ycursor == len(str.strings)
    return
  elseif 0 < str.ycursor < len(str.strings)
    str.ycursor += 1
    carriage_return(str)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_prev_line(str::EditableString)
  if str.ycursor == 0 || str.ycursor == len(str.strings)
    return
  elseif 1 < str.ycursor <= len(str.strings)
    str.ycursor -= 1
    carriage_return(str)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_horizontal_absolute(str::EditableString, x::Unsigned)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)
    str.xcursor = x
    if x > len(str.strings[str.ycursor]) + 1
      str.strings[str.ycursor] *= (" "^(x - (len(str.strings[str.ycursor]) + 1)))
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function cursor_position(str::EditableString, x::Unsigned, y::Unsigned)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)
    str.ycursor = y
    if y > len(str.strings)
      str.strings = append!(str.strings, ["" for _ in len(str.strings):(y-1)])
    end
    cursor_horizontal_absolute(str, x)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function erase_in_display(str::EditableString, n::Unsigned)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)
    if n == 0
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((len(str.strings[str.ycursor]) + 1) - str.xcursor))
      for i in str.ycursor+1:len(str.strings)
        str.strings[i] = (" "^len(str.strings[i]))
      end
    elseif n == 1
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((len(str.strings[str.ycursor]) + 1) - str.xcursor))
      for i in 1:str.ycursor-1
        str.strings[i] = (" "^len(str.strings[i]))
      end
    elseif n == 2 || n == 3
      for i in 1:len(str.strings)
        str.strings[i] = (" "^len(str.strings[i]))
      end
    else
      throw(ArgumentError("n can't be above 3"))
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function erase_in_line(str::EditableString, n::Unsigned)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)
    if n == 0
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((len(str.strings[str.ycursor]) + 1) - str.xcursor))
    elseif n == 1
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((len(str.strings[str.ycursor]) + 1) - str.xcursor))
    elseif n == 2
      str.strings[str.ycursor] = (" "^len(str.strings[str.ycursor]))
    else
      throw(ArgumentError("n can't be above 3"))
    end
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function scroll_up(str::EditableString, n::Unsigned)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)
    str.strings = append!(str.strings, ["" for _ in 1:n])
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function scroll_down(str::EditableString, n::Unsigned)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= len(str.strings)
    str.strings = append!(["" for _ in 1:n], str.strings)
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function newline(str::EditableString)
  if str.ycursor == 0
    str.strings = append!([""^2], str.strings)
    str.ycursor += 2
    str.xcursor = 1
  elseif 0 < str.ycursor <= len(str.strings)
    str.strings = insert!(str.strings, str.ycursor + 1, str.strings[str.ycursor][str.xcursor:end])
    str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1]
    str.ycursor += 1
    str.xcursor = 1
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end