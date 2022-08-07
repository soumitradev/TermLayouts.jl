include("core/core.jl")
include("strings/parseANSI.jl")

function test()
  # Create pipes
  inputpipe = Pipe()
  outputpipe = Pipe()
  errpipe = Pipe()

  Base.link_pipe!(inputpipe, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(outputpipe, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(errpipe, reader_supports_async=true, writer_supports_async=true)

  true_stdout = stdout
  redirect_stdout(outputpipe.in)

  # Link pipes to REPL
  term = REPL.Terminals.TTYTerminal("dumb", inputpipe.out, outputpipe.in, errpipe.in)
  repl = REPL.LineEditREPL(term, true)
  repl.specialdisplay = REPL.REPLDisplay(repl)
  repl.history_file = false

  # Start REPL
  print(true_stdout, "starting REPL...")
  # hook_repl(repl)
  # start_eval_backend()

  repltask = @async begin
    REPL.run_repl(repl)
  end

  # Setup some variables that describe the state of the REPL
  should_exit = false
  keyboard_io = stdin
  replstr = ""

  # Create a console-like object that will make it easier to parse ANSI commands
  virtual_console = EditableString([], 0, 0, "\e[0m")

  # Read output from REPL and process it asynchronously
  @async while !eof(outputpipe)
    data = String(readavailable(outputpipe))

    # Read the output, and process it relative to the current state of the console
    parseANSI(virtual_console, data)
    sleep(1e-2)
  end

  while !should_exit
    # Clear screen
    print(true_stdout, "\e[3J")

    # Create panels and give them default sizes
    fullh, fullw = displaysize(true_stdout)
    lpanelw = Int(round(fullw * 2 / 3))

    # Create panels
    lpanel = Term.Panel(
      replstr,
      width=lpanelw,
      height=fullh - 1,
      style="red"
    )
    rpanel = Term.Panel(
      width=fullw - lpanelw,
      height=fullh - 1,
      style="blue"
    )
    top = lpanel * rpanel

    # # Print the panel
    # print(true_stdout, string(Term.Panel(
    #   top,
    #   width=fullw - 1,
    #   height=fullh - 2,
    # )))
    print(true_stdout, top)

    # Read in keys
    control_value = :CONTROL_VOID
    control_value = read_key(keyboard_io)

    # Exit on Ctrl+C
    if control_value == :EXIT
      should_exit = true
    else
      # Pass down keys to the REPL
      Base.write(inputpipe.in, control_value)
      sleep(0.2)

      # Grab the string that describes the current state of the fake console, and set the panel's text to it
      outstr = to_string(virtual_console)
      replstr = outstr
    end
  end

  # Delete line (^U) and close REPL (^D)
  write(inputpipe.in, "\x15\x04")
  Base.wait(repltask)
  t = @async begin
    close(inputpipe.in)
    close(outputpipe.in)
    close(errpipe.in)
  end
  Base.wait(t)
end

test()