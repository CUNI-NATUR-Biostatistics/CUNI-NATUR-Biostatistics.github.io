#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#               Render extra resources
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

render_extra_resources <- function(
  vec_links,
  label = "Pro vyučující a zájemce"
) {
  if (length(vec_links) == 0L) {
    return("")
  }

  res_extra <-
    paste0(
      "<details class=\"resource-extra\">",
      "<summary>",
      "<i class=\"bi bi-tools\" aria-hidden=\"true\"></i>",
      escape_html(label),
      "</summary>",
      "<div class=\"resource-group resource-group--extra\">",
      paste(vec_links, collapse = ""),
      "</div>",
      "</details>"
    )

  return(res_extra)
}
