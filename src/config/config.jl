mutable struct PanelPrefs
  width::Integer
  title::Union{String,Nothing}
  title_color::Union{String,Nothing}
  border_color::String
end

mutable struct TermLayoutPreferences
  panel1::PanelPrefs
  panel2::PanelPrefs
end
