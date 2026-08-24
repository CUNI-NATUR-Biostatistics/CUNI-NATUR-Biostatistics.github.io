#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Render resource link
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

render_resource_link <- function(label,
                                 href,
                                 primary = FALSE,
                                 external = TRUE,
                                 download = FALSE) {
  class_name <- "resource-link"
  if (isTRUE(primary)) {
    class_name <-
      paste(class_name, "resource-link--primary")
  }

  vec_attributes <-
    c(
      paste0("class=\"", class_name, "\""),
      paste0("href=\"", href, "\"")
    )
  if (isTRUE(external)) {
    vec_attributes <-
      c(
        vec_attributes,
        "target=\"_blank\"",
        "rel=\"noopener\""
      )
  }
  if (isTRUE(download)) {
    vec_attributes <-
      c(vec_attributes, "download")
  }

  res_link <-
    paste0(
      "<a ",
      paste(vec_attributes, collapse = " "),
      ">",
      escape_html(label),
      "</a>"
    )

  return(res_link)
}
