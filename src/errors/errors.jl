
struct EvalError
  err::Any
  bt::Any
end

struct EvalErrorStack
  stack::Any
end

function crop_backtrace(bt)
  i = find_first_topelevel_scope(bt)
  return bt[1:(i === nothing ? end : i)]
end

function find_first_topelevel_scope(bt::Vector{<:Union{Base.InterpreterIP,Ptr{Cvoid}}})
  for (i, ip) in enumerate(bt)
    st = Base.StackTraces.lookup(ip)
    ind = findfirst(st) do frame
      linfo = frame.linfo
      if linfo isa Core.CodeInfo
        linetable = linfo.linetable
        if isa(linetable, Vector) && length(linetable) ≥ 1
          lin = first(linetable)
          if isa(lin, Core.LineInfoNode) && lin.method === Symbol("top-level scope")
            return true
          end
        end
      else
        return frame.func === Symbol("top-level scope")
      end
    end
    ind === nothing || return i
  end
  return
end
