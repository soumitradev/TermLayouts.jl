mutable struct EditableString
  strings::Array{String}
  xcursor::Unsigned
  ycursor::Unsigned
  # function EditableString()
  #   self.strings = []
  #   this.xcursor = 0
  #   self.ycursor = 0
  # end
end

function enterchar(str::EditableString, char::Char)
  if str.ycursor == 0
    str.strings = insert!(str.strings, 1, string(char))
    str.ycursor = 1
    str.xcursor = 2
  elseif 0 < str.ycursor <= length(str.strings)
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
  elseif 0 < str.ycursor <= length(str.strings)

    if 0 < str.ycursor < length(str.strings)
      str.ycursor += 1
    else
      str.ycursor += 1
      str.strings = insert!(str.strings, str.ycursor, "")
    end

    if str.xcursor > length(str.strings[str.ycursor]) + 1
      str.strings[str.ycursor] = str.strings[str.ycursor] * (" "^(str.xcursor - length(str.strings[str.ycursor]) - 1))
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
    str.strings[str.ycursor] *= " "
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
      str.strings[str.ycursor] = str.strings[str.ycursor] * (" "^(str.xcursor - length(str.strings[str.ycursor]) - 1))
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
      str.strings[str.ycursor] *= (" "^(x - (length(str.strings[str.ycursor]) + 1)))
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
      str.strings = append!(str.strings, ["" for _ in length(str.strings):(y-1)])
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
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((length(str.strings[str.ycursor]) + 1) - str.xcursor))
      for i in str.ycursor+1:length(str.strings)
        str.strings[i] = (" "^length(str.strings[i]))
      end
    elseif n == 1
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((length(str.strings[str.ycursor]) + 1) - str.xcursor))
      for i in 1:str.ycursor-1
        str.strings[i] = (" "^length(str.strings[i]))
      end
    elseif n == 2 || n == 3
      for i in 1:length(str.strings)
        str.strings[i] = (" "^length(str.strings[i]))
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
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((length(str.strings[str.ycursor]) + 1) - str.xcursor))
    elseif n == 1
      str.strings[str.ycursor] = str.strings[str.ycursor][1:str.xcursor-1] * (" "^((length(str.strings[str.ycursor]) + 1) - str.xcursor))
    elseif n == 2
      str.strings[str.ycursor] = (" "^length(str.strings[str.ycursor]))
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
    str.strings = append!(str.strings, ["" for _ in 1:n])
  else
    throw(BoundsError(str.strings, str.ycursor))
  end
end

function scroll_down(str::EditableString, n::Int)
  if str.ycursor == 0
    return
  elseif 0 < str.ycursor <= length(str.strings)
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
  return join(str.strings, "\n")
end