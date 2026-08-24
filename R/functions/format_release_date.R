#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Format release date
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

format_release_date <- function(release_tag) {
  date_text <-
    sub(
      pattern = ".*-([0-9]{8})(-moodle)?$",
      replacement = "\\1",
      x = release_tag
    )
  date_value <-
    as.Date(date_text, format = "%Y%m%d")

  if (is.na(date_value)) {
    return("")
  }

  res_date <-
    format(date_value, format = "%d. %m. %Y")

  return(res_date)
}
