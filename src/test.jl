include("core/core.jl")

function test()
  fullh = Int(round(Term.consoles.console_height()))
  fullw = Int(round(Term.consoles.console_width()))
  lpanelw = Int(round(fullw * 2 / 3))
  lpanel = Term.Panel(
    width=lpanelw - 4,
    height=fullh - 2,
    style="red"
  )
  line = " " / Term.vLine(lpanel.measure.h - 2; style="dim bold")
  rpanel = Term.Panel(
    width=fullw - lpanelw - 2,
    height=fullh - 2,
    style="blue"
  )

  # Create pipes
  inputbuf = Pipe()
  outputbuf = Pipe()
  errbuf = Pipe()

  Base.link_pipe!(inputbuf, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(outputbuf, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(errbuf, reader_supports_async=true, writer_supports_async=true)

  term = REPL.Terminals.TTYTerminal("dumb", inputbuf.out, outputbuf.in, errbuf.in)
  repl = REPL.LineEditREPL(term, true)
  repl.specialdisplay = REPL.REPLDisplay(repl)
  repl.history_file = false

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

  current_prompt = ""

  println("running setup cmds")
  for cmd in setup_commands
    write(inputbuf.in, cmd)
    sleep(0.5)
    current_prompt = split(String(readavailable(outputbuf.out)), '\n')
    current_prompt = current_prompt[length(current_prompt)]
  end
  println("finished setup cmds")

  should_exit = false
  keyboard_io = stdin
  curcmd = ""
  cmdcursor = 1
  cmdhist = []
  cmdhistcursor = -1
  print(current_prompt)
  while !should_exit
    top = lpanel * rpanel
    # print(Term.Panel(
    #   top,
    #   width=fullw,
    #   height=fullh,
    # ))
    # sleep(1 / 15) # 10ms should be enough for most keyboard event

    control_value = :CONTROL_VOID
    control_value = read_key(keyboard_io)

    if control_value == :EXIT
      should_exit = true
    elseif control_value == :ENTER
      LAST_CMD_WAS_ERR[] = false
      write(inputbuf.in, curcmd * "\n")
      write(inputbuf.in, "__TERMLAYOUTS__term_end(1)\n")
      sleep(0.2)
      outarr = split(String(readuntil(outputbuf.out, "\"__TERMLAYOUTS__TERM_END_1\"\n")), '\n')
      outstr = join(outarr[1:length(outarr)-2], "\n")
      if LAST_CMD_WAS_ERR[]
        println()
      else
        if (length(cmdhist) > 0)
          print("\x1b[1A")
          print("\x1b[2K")
        end
        println(outstr)
      end
      print(current_prompt)
      # lpanel.content *= outstr
      push!(cmdhist, String(curcmd))
      curcmd = ""
      cmdcursor = 1
      cmdhistcursor = length(cmdhist) + 1
    elseif control_value == :ARROW_LEFT
      if cmdcursor > 1
        print("\e[D")
        cmdcursor -= 1
      end
    elseif control_value == :ARROW_RIGHT
      if cmdcursor < length(curcmd) + 1
        print("\e[C")
        cmdcursor += 1
      end
    elseif control_value == '\e' * '[' * 'A'
      if length(cmdhist) > 0
        # print("\x1b[1A")
        if cmdhistcursor < 0
          cmdhistcursor = length(cmdhist)
        elseif cmdhistcursor == 1
        else
          cmdhistcursor -= 1
        end
        print("\x1b[2K")
        print(current_prompt)
        print(cmdhist[cmdhistcursor])
        curcmd = cmdhist[cmdhistcursor]
        cmdcursor = length(cmdhist[cmdhistcursor]) + 1
      end
    elseif control_value == '\e' * '[' * 'B'
      # println(cmdhistcursor)
      # println(length(cmdhist))
      if cmdhistcursor < length(cmdhist) + 1
        # print("\x1b[1A")
        print("\x1b[2K")
        print(current_prompt)
        cmdhistcursor += 1
        if cmdhistcursor < length(cmdhist) + 1
          print(cmdhist[cmdhistcursor])
          curcmd = cmdhist[cmdhistcursor]
          cmdcursor = length(cmdhist[cmdhistcursor]) + 1
        else
          curcmd = ""
          cmdcursor = 1
        end
      end
    elseif control_value == :BACKSPACE
      if cmdcursor > 1
        if cmdcursor == length(curcmd) + 1
          cmdcursor -= 1
          print('\x08')
          print("\x1b[0K")
          curcmd = String(append!(collect(curcmd[1:cmdcursor-1]), collect(curcmd[cmdcursor+1:length(curcmd)])))
        else
          cmdcursor -= 1
          print("\x1b[2K")
          print(current_prompt)
          curcmd = String(append!(collect(curcmd[1:cmdcursor-1]), collect(curcmd[cmdcursor+1:length(curcmd)])))
          print(curcmd)
          print("\e[$(length(curcmd) - cmdcursor + 1)D")
        end
      end
    else
      # - Render text to panel
      # TODO: Handle backspaces and arrow keys, and render text to panel
      if cmdcursor == length(curcmd) + 1
        curcmd *= string(control_value)
        cmdcursor += 1
        print(control_value)
      else
        # curcmd *= string(control_value)
        curcmd = String(insert!(collect(curcmd), cmdcursor, control_value))
        cmdcursor += 1
        print("\x1b[2K")
        print(current_prompt)
        print(curcmd)
        print("\e[$(length(curcmd) - cmdcursor + 1)D")
        # lpanel.content *= String(control_value)
      end
    end

    # write(inputbuf, control_value)
    sleep(1e-2) # 10ms should be enough for most keyboard event
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