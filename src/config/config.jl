mutable struct PanelPrefs
  width::Integer
  title::String
  title_color::String
  border_color::String
end

mutable struct TermLayoutPreferences
  panel1::PanelPrefs
  panel2::PanelPrefs
end
