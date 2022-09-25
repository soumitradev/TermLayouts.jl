# Home

The home for TermLayouts.jl documentation.

## Quickstart

Install TermLayouts:

```julia
pkg> add https://github.com/soumitradev/TermLayouts.jl.git
```

Run TermLayouts.jl by running the run() function in the REPL:

```julia
julia> using TermLayouts

julia> TermLayouts.run()
starting REPL...
```

## Configuration

<!-- TODO: Elaborate here -->
TermLayouts.jl comes with it's default config, which is:

```toml
[TermLayouts]
  [TermLayouts.panels.left]
  width = 70
  title = ""
  title_color = ""
  border_color = "red"

  [TermLayouts.panels.right]
  width = 30
  title = ""
  title_color = ""
  border_color = "blue"
```

!!! note "TermLayouts' scoped configuration"
    If a TermLayouts config exists in the global scope, it will apply to all projects that run in the global scope. If a TermLayouts config file exists in the environment that has been activated, it use that config file. The config file needs to be in the working directory of that environment, and should be named `LocalPreferences.toml` 

A TermLayouts config file is fairly simple. It can be described by the following two structures:

```@docs
TermLayouts.TermLayoutsPreferences
TermLayouts.PanelPrefs
```

TermLayouts is limited to two panels as of now, due to limited types of panel implementations.

!!! warning "Width overflow"
    If your panel widths don't add up to 100 or less than 100, it will crop your gith panel by default

The config file can be described with the above two structs, but in reality looks something like:

```toml
[TermLayouts]
  [TermLayouts.panels.left]
  width = 80
  title = "REPL"
  title_color = "blue"
  border_color = "blue"

  [TermLayouts.panels.right]
  width = 20
  title = "Plots"
  title_color = "red"
  border_color = "red"
```

The TOML format is pretty self explanatory.