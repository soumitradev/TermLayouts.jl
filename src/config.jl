using Configurations

"""
Describe the configuration of a Panel in TermLayouts

# Fields
- `width`: Percentage of the maximum width the panel takes up
- `title`: Panel title text
- `title_color`: Panel title text color. See [here](https://fedeclaudi.github.io/Term.jl/stable/basics/colors_and_theme/)
- `border_color`: Panel border color. See [here](https://fedeclaudi.github.io/Term.jl/stable/basics/colors_and_theme/)
"""
@option "panel" mutable struct PanelPrefs
  width::Integer
  title::String
  title_color::String
  border_color::String
end

"""
Describe the layout of Panels in TermLayouts

# Fields
- `panel1`: Left Panel
- `panel2`: Right Panel
"""
mutable struct TermLayoutsPreferences
  panel1::PanelPrefs
  panel2::PanelPrefs
end
