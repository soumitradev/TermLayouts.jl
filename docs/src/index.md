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

A TermLayouts config file is fairly simple. It can be dedescribed by the following two structures:

```@docs
TermLayouts.TermLayoutPreferences
TermLayouts.PanelPrefs
```

TermLayouts is limited to two panels as of now, due to limited types of panel implementations.

!!! note "TermLayout's scoped configuration"
    If TermLayouts is the globally-installed TermLayouts, and not a version from your environment, then TermLayouts uses a global configuration for itself.

    If installed in an environment, TermLayouts creates a config file for itself inside that environment.

The config file can be described with the above two structs, but in reality looks something like:

```toml
[TermLayouts]
panelL_width = 80
panelL_title = "REPL"
panelL_title_color = "blue"
panelL_border_color = "blue"
panelR_width = 20
panelR_title = "Plots"
panelR_title_color = "red"
panelR_border_color = "red"
```

The TOML format is pretty self explanatory.