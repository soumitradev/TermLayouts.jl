include("../errors/errors.jl")

_setraw!(io::Base.TTY, raw) = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), io.handle, raw)
_setraw!(::IO, raw) = nothing

function read_key(io=stdin)
  control_value = :CONTROL_VOID
  try
    _setraw!(io, true)
    keyin = read(io, Char)
    if keyin == '\e'
      # some special keys are more than one byte, e.g., left key is `\e[D`
      # reference: https://en.wikipedia.org/wiki/ANSI_escape_code
      keyin = read(io, Char)
      if keyin == '['
        keyin = read(io, Char)
        if keyin == 'A'
          control_value = '\e' * '[' * 'A'
        elseif keyin == 'D'
          control_value = '\e' * '[' * 'D'
        elseif keyin == 'B'
          control_value = '\e' * '[' * 'B'
        elseif keyin == 'C'
          control_value = '\e' * '[' * 'C'
        end
      end
    elseif keyin == '\x03'
      control_value = :EXIT
    else
      control_value = keyin
    end
  catch e
    if e isa InterruptException # Ctrl-C
      control_value = :EXIT
    else
      rethrow(e)
    end
  finally
    _setraw!(io, false)
  end
  return control_value
end

# basically the same as Base's `display_error`, with internal frames removed
function display_repl_error(io, err, bt)
  st = stacktrace(crop_backtrace(bt))
  println()
  printstyled(io, "The next lines will describe an error: "; bold=true, color=Base.error_color())
  println()
  printstyled(io, "ERROR: "; bold=true, color=Base.error_color())
  showerror(IOContext(io, :limit => true), err, st)
  println(io)
end
