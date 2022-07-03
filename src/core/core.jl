import Term
using REPL
using REPL.LineEdit

include("../io/io.jl")

const EVAL_CHANNEL_IN = Channel(0)
const EVAL_CHANNEL_OUT = Channel(0)
const EVAL_BACKEND_TASK = Ref{Any}(nothing)
const IS_BACKEND_WORKING = Ref{Bool}(false)
const LAST_CMD_WAS_ERR = Ref{Bool}(false)

# Workaround for https://github.com/julia-vscode/julia-vscode/issues/1940
struct Wrapper
  content::Any
end
wrap(x) = Wrapper(x)
function unwrap(x)
  return x.content()
end

const HAS_REPL_TRANSFORM = Ref{Bool}(false)
function hook_repl(repl)
  if HAS_REPL_TRANSFORM[]
    return
  end
  @debug "installing REPL hook"
  if !isdefined(repl, :interface)
    repl.interface = REPL.setup_interface(repl)
  end
  main_mode = get_main_mode(repl)

  if VERSION > v"1.5-"
    for _ = 1:20 # repl backend should be set up after 10s -- fall back to the pre-ast-transform approach otherwise
      isdefined(Base, :active_repl_backend) && continue
      sleep(0.5)
    end
    if isdefined(Base, :active_repl_backend)
      push!(Base.active_repl_backend.ast_transforms, ast -> transform_backend(ast, repl, main_mode))
      HAS_REPL_TRANSFORM[] = true
      @debug "REPL AST transform installed"
      return
    end
  end

  main_mode.on_done = REPL.respond(repl, main_mode; pass_empty=false) do line
    quote
      $(evalrepl)(Main, $line, $repl, $main_mode)
    end
  end
  @debug "legacy REPL hook installed"
  HAS_REPL_TRANSFORM[] = true
  return nothing
end

function transform_backend(ast, repl, main_mode)
  quote
    $(evalrepl)(Main, $(QuoteNode(ast)), $repl, $main_mode)
  end
end

function is_evaling()
  return IS_BACKEND_WORKING[]
end

function run_with_backend(f, args...)
  put!(EVAL_CHANNEL_IN, (f, args))
  return unwrap(take!(EVAL_CHANNEL_OUT))
end

function start_eval_backend()
  global EVAL_BACKEND_TASK[] = @async begin
    Base.sigatomic_begin()
    while true
      try
        f, args = take!(EVAL_CHANNEL_IN)
        Base.sigatomic_end()
        IS_BACKEND_WORKING[] = true
        res = try
          Base.invokelatest(f, args...)
        catch err
          @static if isdefined(Base, :current_exceptions)
            EvalErrorStack(Base.current_exceptions(current_task()))
          elseif isdefined(Base, :catch_stack)
            EvalErrorStack(Base.catch_stack())
          else
            EvalError(err, catch_backtrace())
          end
        end
        IS_BACKEND_WORKING[] = false
        Base.sigatomic_begin()
        put!(EVAL_CHANNEL_OUT, wrap(res))
      catch err
        put!(EVAL_CHANNEL_OUT, wrap(err))
      finally
        IS_BACKEND_WORKING[] = false
      end
    end
    Base.sigatomic_end()
  end
end

function repl_interrupt_request(conn, ::Nothing)
  println(stderr, "^C")
  if EVAL_BACKEND_TASK[] !== nothing && !istaskdone(EVAL_BACKEND_TASK[]) && IS_BACKEND_WORKING[]
    schedule(EVAL_BACKEND_TASK[], InterruptException(); error=true)
  end
end

function get_main_mode(repl=Base.active_repl)
  mode = repl.interface.modes[1]
  mode isa LineEdit.Prompt || error("no julia repl mode found")
  mode
end

function evalrepl(m, line, repl, main_mode)
  return try
    r = run_with_backend() do
      f = () -> repleval(m, line, REPL.repl_filename(repl, main_mode.hist))
    end
    if r isa EvalError
      display_repl_error(stderr, r.err, r.bt)
      nothing
    else
      r
    end
  catch err
    # This is for internal errors only.
    # Base.display_error(stderr, err, catch_backtrace())
    display_repl_error(stderr, err, catch_backtrace())
    LAST_CMD_WAS_ERR[] = true
    nothing
  end
end

# don't inline this so we can find it in the stacktrace
@noinline function repleval(m, code::String, file)
  args = VERSION >= v"1.5" ? (REPL.softscope, m, code, file) : (m, code, file)
  return include_string(args...)
end

@noinline function repleval(m, code, _)
  return Base.eval(m, code)
end
