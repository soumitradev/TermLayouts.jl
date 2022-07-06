using Term

include("core/core.jl")

function test()
  # Create pipes
  inputbuf = Pipe()
  outputbuf = Pipe()
  errbuf = Pipe()

  Base.link_pipe!(inputbuf, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(outputbuf, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(errbuf, reader_supports_async=true, writer_supports_async=true)

  # Link pipes to REPL
  term = REPL.Terminals.TTYTerminal("dumb", inputbuf.out, outputbuf.in, errbuf.in)
  repl = REPL.LineEditREPL(term, true)
  repl.specialdisplay = REPL.REPLDisplay(repl)
  repl.history_file = false

  # Start REPL
  println("starting REPL...")
  hook_repl(repl)
  start_eval_backend()
  println("finished starting REPL")

  repltask = @async begin
    REPL.run_repl(repl)
  end

  # Try running commands and test REPL redirection
  setup_commands = [
    "__TERMLAYOUTS__term_end(x) = \"__TERMLAYOUTS__TERM_END_\" * string(x)\n",
  ]

  # Run setup commands, and get the current prompt string
  current_prompt = ""

  println("running setup cmds")
  for cmd in setup_commands
    write(inputbuf.in, cmd)
    sleep(1)
    current_prompt = split(String(readavailable(outputbuf.out)), '\n')
    current_prompt = current_prompt[length(current_prompt)]
  end
  println("finished setup cmds")

  # Setup some variables that describe the state of the REPL
  should_exit = false
  keyboard_io = stdin
  curcmd = ""
  cmdcursor = 1
  cmdhist = []
  cmdhistcursor = -1
  replstr = ""
  # print(current_prompt)
  replstr *= current_prompt

  while !should_exit
    # Clear screen
    print("\e[2J")
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
    # line = " " / Term.vLine(lpanel.measure.h - 2; style="dim bold")
    rpanel = Term.Panel(
      width=fullw - lpanelw - 2,
      height=fullh - 3,
      style="blue"
    )
    top = lpanel * rpanel
    # print(Term.Panel(
    #   top,
    #   width=fullw,
    #   height=fullh - 1,
    # ))
    print(replstr)
    # sleep(1 / 15) # 10ms should be enough for most keyboard event

    # Read in keys
    control_value = :CONTROL_VOID
    control_value = read_key(keyboard_io)

    # Exit on Ctrl+C
    if control_value == :EXIT
      should_exit = true
    elseif control_value == :ENTER
      # Write and Read from REPL buffers
      LAST_CMD_WAS_ERR[] = false
      write(inputbuf.in, curcmd * "\n")
      write(inputbuf.in, "__TERMLAYOUTS__term_end(1)\n")
      sleep(0.2)
      outarr = split(String(readuntil(outputbuf.out, "\"__TERMLAYOUTS__TERM_END_1\"\n")), '\n')
      outstr = join(outarr[1:length(outarr)-2], "\n")

      if LAST_CMD_WAS_ERR[]
        # Stray newline for printing errors properly
        # println()
        replstr *= "\n"
      else
        # Delete last line
        if (length(cmdhist) > 0)
          reploutarr = split(replstr, '\n')
          replstr = join(reploutarr[1:length(reploutarr)-1], "\n")
        end
        # print output of command
        # println(outstr)
        replstr *= outstr * "\n"
      end
      # Print the prompt for the next prompt, and add command to command history
      # print(current_prompt)
      replstr *= current_prompt
      push!(cmdhist, String(curcmd))
      curcmd = ""
      cmdcursor = 1
      cmdhistcursor = length(cmdhist) + 1
    elseif control_value == :ARROW_LEFT
      # Allow using arrows to move cursor, update cursor value
      if cmdcursor > 1
        print("\e[D")
        cmdcursor -= 1
      end
    elseif control_value == :ARROW_RIGHT
      # Allow using arrows to move cursor, update cursor value
      if cmdcursor < length(curcmd) + 1
        print("\e[C")
        cmdcursor += 1
      end
    elseif control_value == '\e' * '[' * 'A'
      # Move through command history
      if length(cmdhist) > 0
        # Keep history cursor in bounds
        if cmdhistcursor < 0
          cmdhistcursor = length(cmdhist)
        elseif cmdhistcursor == 1
        else
          cmdhistcursor -= 1
        end
        # Delete what was typed before, and replace it with the command in history
        reploutarr = collect(split(replstr, '\n'))
        reploutarr = reploutarr[1:length(reploutarr)-1]
        reploutarr = push!(reploutarr, current_prompt * cmdhist[cmdhistcursor])
        # print("\x1b[2K")
        # print(current_prompt)
        # print(cmdhist[cmdhistcursor])

        # replstr *= current_prompt
        # replstr *= cmdhist[cmdhistcursor]

        replstr = join(reploutarr, "\n")

        print("\e[2J")
        print(replstr)

        curcmd = cmdhist[cmdhistcursor]
        cmdcursor = length(cmdhist[cmdhistcursor]) + 1
      end
    elseif control_value == '\e' * '[' * 'B'
      # println(cmdhistcursor)
      # println(length(cmdhist))
      # Move through command history
      if cmdhistcursor < length(cmdhist) + 1
        # print("\x1b[1A")
        # Clear line and replace command
        reploutarr = collect(split(replstr, '\n'))
        reploutarr = reploutarr[1:length(reploutarr)-1]
        # print("\x1b[2K")
        # print(current_prompt)
        curstr = current_prompt
        cmdhistcursor += 1
        if 0 < cmdhistcursor < length(cmdhist) + 1
          # print(cmdhist[cmdhistcursor])
          curstr *= cmdhist[cmdhistcursor]
          curcmd = cmdhist[cmdhistcursor]
          cmdcursor = length(cmdhist[cmdhistcursor]) + 1
        else
          curcmd = ""
          cmdcursor = 1
        end
        reploutarr = push!(reploutarr, curstr)
        replstr = join(reploutarr, "\n")
      end
    elseif control_value == :BACKSPACE
      if cmdcursor > 1
        # Either remove characters from the end or remove characters in between the typed command
        if cmdcursor == length(curcmd) + 1
          cmdcursor -= 1
          # print('\x08')
          # print("\x1b[0K")
          replstr = replstr[1:length(replstr)-1]
          curcmd = String(append!(collect(curcmd[1:cmdcursor-1]), collect(curcmd[cmdcursor+1:length(curcmd)])))
        else
          cmdcursor -= 1
          reploutarr = split(replstr, '\n')
          replstr = join(reploutarr[1:length(reploutarr)-2], "\n")
          # print("\x1b[2K")
          # print(current_prompt)
          replstr *= current_prompt
          curcmd = String(append!(collect(curcmd[1:cmdcursor-1]), collect(curcmd[cmdcursor+1:length(curcmd)])))
          # print(curcmd)
          replstr *= curcmd
          print("\e[$(length(curcmd) - cmdcursor + 1)D")
        end
      end
    else
      # If cursor is at the end of prompt, add character at end
      if cmdcursor == length(curcmd) + 1
        curcmd *= string(control_value)
        cmdcursor += 1
        # print(control_value)
        replstr *= control_value
      else
        # If cursor is in the middle of prompt, add character in middle
        curcmd = String(insert!(collect(curcmd), cmdcursor, control_value))
        cmdcursor += 1
        # print("\x1b[2K")
        reploutarr = split(replstr, '\n')
        replstr = join(reploutarr[1:length(reploutarr)-2], "\n")
        # print(current_prompt)
        replstr *= current_prompt
        # print(curcmd)
        replstr *= curcmd
        print("\e[$(length(curcmd) - cmdcursor + 1)D")
        # lpanel.content *= String(control_value)
      end
    end
    # write(inputbuf, control_value)
    # sleep(1e-2) # 10ms should be enough for most keyboard event
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