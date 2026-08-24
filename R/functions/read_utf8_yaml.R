#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                   Read UTF-8 YAML
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

read_utf8_yaml <- function(path) {
  vec_lines <-
    readLines(
      con = path,
      encoding = "UTF-8",
      warn = FALSE
    )
  yaml_text <-
    paste(vec_lines, collapse = "\n")
  res_yaml <-
    yaml::yaml.load(string = yaml_text)

  return(res_yaml)
}
