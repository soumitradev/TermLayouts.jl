include("./strings.jl")

# https://en.wikipedia.org/wiki/ANSI_escape_code
function simplifyANSI(str::String)
  console = EditableString([], 0, 0, "\e[0m")
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