include("core/core.jl")
include("strings/parseANSI.jl")
include("customio/customio.jl")

function test()
  # Create pipes
  inputbuf = Pipe()
  outputbuf = Pipe()
  errbuf = Pipe()

  Base.link_pipe!(inputbuf, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(outputbuf, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(errbuf, reader_supports_async=true, writer_supports_async=true)

  diffinputbuf = Pipe()
  diffoutputbuf = Pipe()
  differrbuf = Pipe()
  idk = CustomIO(diffinputbuf, diffoutputbuf, differrbuf)

  # Link pipes to REPL
  term = REPL.Terminals.TTYTerminal("dumb", inputbuf.out, outputbuf.in, errbuf.in)
  repl = REPL.LineEditREPL(term, true)
  repl.specialdisplay = REPL.REPLDisplay(repl)
  repl.history_file = false

  # Start REPL
  print("starting REPL...")

  redirect_stdout(idk)

  # Even if I disconnect any code that's interfering with the REPL, it still does the same thing
  # hook_repl(repl)
  # start_eval_backend()

  repltask = @async begin
    REPL.run_repl(repl)
  end

  # Run setup commands, and get the current prompt string
  sleep(1)
  current_prompt = string(strip(simplifyANSI(String(readavailable(outputbuf.out)))))

  # Setup some variables that describe the state of the REPL
  should_exit = false
  keyboard_io = stdin
  replstr = ""
  replstr *= current_prompt

  # Create a console-like object that will make it easier to parse ANSI commands
  curcons = EditableString([], 0, 0, "\e[0m")
  parseANSI(curcons, current_prompt)

  while !should_exit
    # Clear screen
    print("\e[3J")
    # Create panels and give them default sizes
    fullh = Int(round(Term.Consoles.console_height()))
    fullw = Int(round(Term.Consoles.console_width()))
    lpanelw = Int(round(fullw * 2 / 3))
    lpanel = Term.Panel(
      replstr,
      width=lpanelw - 4,
      height=fullh - 3,
      style="red"
    )
    rpanel = Term.Panel(
      width=fullw - lpanelw - 2,
      height=fullh - 3,
      style="blue"
    )
    top = lpanel * rpanel

    # Print the panel
    Base.write(idk, string(Term.Panel(
      top,
      width=fullw,
      height=fullh - 1,
    )))

    # Read in keys
    control_value = :CONTROL_VOID
    control_value = read_key(keyboard_io)

    # Exit on Ctrl+C
    if control_value == :EXIT
      should_exit = true
    else
      # Pass down keys to the REPL
      Base.write(inputbuf.in, control_value)
      sleep(0.2)
      # Read the output, and process it relative to the current state of the console
      outarr = String(readavailable(outputbuf.out))
      parseANSI(curcons, outarr)

      # Grab the string that describes the current state of the fake console, and set the panel's text to it
      outstr = to_string(curcons)
      replstr = outstr
    end
  end

  # Delete line (^U) and close REPL (^D)
  write(inputbuf.in, "\x15\x04")
  Base.wait(repltask)
  t = @async begin
    close(inputbuf.in)
    close(outputbuf.in)
    close(errbuf.in)
  end
  Base.wait(t)
end

test()