#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                   Escape YAML text
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

escape_yaml_text <- function(text) {
  res_text <-
    gsub(
      pattern = "\"",
      replacement = "\\\\\"",
      x = text,
      fixed = TRUE
    )

  return(res_text)
}
