#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                     Escape HTML
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

escape_html <- function(text) {
  res_text <-
    as.character(
      htmltools::htmlEscape(
        text = text,
        attribute = FALSE
      )
    )

  return(res_text)
}
