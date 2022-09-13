"Describe the configuration of a Panel in TermLayouts"
mutable struct PanelPrefs
  width::Integer
  title::String
  title_color::String
  border_color::String
end

"Describe the layout of Panels in TermLayouts"
mutable struct TermLayoutPreferences
  panel1::PanelPrefs
  panel2::PanelPrefs
end
