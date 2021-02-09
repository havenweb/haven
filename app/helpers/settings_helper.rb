module SettingsHelper
  def font_filename_to_name(filename)
    filename.to_s.rpartition(".").first.delete(" \t\r\n")
  end
end
