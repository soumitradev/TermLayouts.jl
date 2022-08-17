module TermLayouts

using Preferences

include("core/core.jl")
include("strings/parseANSI.jl")
include("config/config.jl")

export activate

function loadprefs()
  panelL_width = @load_preference("panelL_width", 70)
  panelL_title = @load_preference("panelL_title", "")
  panelL_title_color = @load_preference("panelL_title_color", "")
  panelL_border_color = @load_preference("panelL_border_color", "red")

  panelR_width = @load_preference("panelR_width", 30)
  panelR_title = @load_preference("panelR_title", "")
  panelR_title_color = @load_preference("panelR_title_color", "")
  panelR_border_color = @load_preference("panelR_border_color", "blue")

  if (panelL_width + panelR_width) > 100
    @warn "Panel widths add up to more than 100, cropping right panel."
    panelR_width = 100 - panelL_width
  end

  panelL_prefs = PanelPrefs(panelL_width, panelL_title, panelL_title_color, panelL_border_color)
  panelR_prefs = PanelPrefs(panelR_width, panelR_title, panelR_title_color, panelR_border_color)

  return TermLayoutPreferences(panelL_prefs, panelR_prefs)
end

function activate()
  prefs = loadprefs()

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
  hook_repl(repl)
  start_eval_backend()

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
    parseANSI(virtual_console, data, true)
    sleep(1e-2)
  end

  # Render the layout asynchronously
  @async while !should_exit
    # Create panels and give them default sizes
    fullh, fullw = displaysize(true_stdout)
    lpanelw = Int(round(fullw * prefs.panel1.width / 100))
    rpanelw = Int(round(fullw * prefs.panel2.width / 100))

    # Grab the string that describes the current state of the fake console, and set the panel's text to it
    outstr = to_string(virtual_console, true)
    # Reshape text
    reshaped = Term.reshape_text(outstr, lpanelw - 3)
    # Get last few lines
    reshaped_lines = split(reshaped, "\n")
    reshaped_cropped = reshaped_lines[max(1, length(reshaped_lines) - fullh + 3):end]

    last_line = string(reshaped_cropped[max(1, length(reshaped_cropped) - 1)])

    text_before_cursor = simplifyANSI(last_line, false)
    # TODO: Allow cursor to move around after
    cursorX = length(text_before_cursor) + 3
    cursorY = length(reshaped_cropped)

    final_outstr = join(reshaped_cropped, "\n")
    replstr = final_outstr

    # Create panels
    lpanel = Term.Panel(
      replstr,
      width=lpanelw,
      height=fullh,
      style="red"
    )
    rpanel = Term.Panel(
      width=rpanelw,
      height=fullh,
      style="blue"
    )
    top = lpanel * rpanel


    # Clear screen and print the panel
    # print(true_stdout, string(Term.Panel(
    #   top,
    #   width=fullw - 1,
    #   height=fullh - 2,
    # )))
    # print(true_stdout, "\e[2J")
    print(true_stdout, "\e[3J")
    print(true_stdout, "\e[1;1H")
    print(true_stdout, string(top))

    print(true_stdout, "\e[" * string(cursorY) * ";" * string(cursorX) * "H")

    sleep(1 / 30)
  end

  while !should_exit
    # Read in keys
    control_value = :CONTROL_VOID
    control_value = read_key(keyboard_io)

    # Exit on Ctrl+C
    if control_value == :EXIT
      should_exit = true
    else
      # Pass down keys to the REPL
      write(inputpipe.in, control_value)
    end
    sleep(1e-2)
  end

  # Delete line (^U) and close REPL (^D)
  write(inputpipe.in, "\x15\x04")

  print(true_stdout, "\e[2J")
  print(true_stdout, "\e[3J")
  print(true_stdout, "\e[1;1H")

  Base.wait(repltask)
  t = @async begin
    close(inputpipe.in)
    close(outputpipe.in)
    close(errpipe.in)
  end
  Base.wait(t)
end

end