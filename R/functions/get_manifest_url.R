#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                 Get manifest URL
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

get_manifest_url <- function(base_url, lesson_id, release_tag = NULL) {
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
      "/manifest.json"
    )

  return(res_url)
}
