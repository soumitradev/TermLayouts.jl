mutable struct CustomIO <: Base.AbstractPipe
  in::IO
  out::IO
  err::IO

  function CustomIO(in, out, err)
    Base.link_pipe!(in, reader_supports_async=true, writer_supports_async=true)
    Base.link_pipe!(out, reader_supports_async=true, writer_supports_async=true)
    Base.link_pipe!(err, reader_supports_async=true, writer_supports_async=true)
    return new(in, out, err)
  end
end

function write(io::CustomIO, c)
  test = open("idk.txt", "w+")
  Base.write(test, c * "  => " * current_task())
  close(test)
  Base.write(io.in, c)
end

Base.pipe_writer(io::CustomIO) = io.in