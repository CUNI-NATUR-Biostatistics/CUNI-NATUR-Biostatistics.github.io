#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#              Get material base URL
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

get_material_base_url <- function(
  base_url,
  lesson_id,
  release_tag = NULL
) {
  route <- "current"
  if (!is.null(release_tag)) {
    route <-
      paste0("releases/", release_tag)
  }

  res_url <-
    paste0(
      sub("/$", "", base_url),
      "/",
      lesson_id,
      "/",
      route,
      "/"
    )

  return(res_url)
}
