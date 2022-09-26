import Term
using REPL
using REPL.LineEdit

"A struct to describe the state of TermLayouts"
mutable struct TermLayoutsState
  EVAL_CHANNEL_IN::Channel
  EVAL_CHANNEL_OUT::Channel
  EVAL_BACKEND_TASK::Any
  IS_BACKEND_WORKING::Bool
  LAST_CMD_WAS_ERR::Bool
  HAS_REPL_TRANSFORM::Bool

  TermLayoutsState() = new(Channel(0), Channel(0), nothing, false, false, false)
end

"Workaround for https://github.com/julia-vscode/julia-vscode/issues/1940"
struct Wrapper
  content::Any
end
wrap(x) = Wrapper(x)
unwrap(x) = x.content

"Start the backend that will evaluate our expressions"
function start_eval_backend(state)
  state.EVAL_BACKEND_TASK = @async begin
    Base.sigatomic_begin()
    while true
      try
        f, args = take!(state.EVAL_CHANNEL_IN)
        Base.sigatomic_end()
        state.IS_BACKEND_WORKING = true
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
        state.IS_BACKEND_WORKING = false
        Base.sigatomic_begin()
        put!(state.EVAL_CHANNEL_OUT, wrap(res))
      catch err
        put!(state.EVAL_CHANNEL_OUT, wrap(err))
      finally
        state.IS_BACKEND_WORKING = false
      end
    end
    Base.sigatomic_end()
  end
end
