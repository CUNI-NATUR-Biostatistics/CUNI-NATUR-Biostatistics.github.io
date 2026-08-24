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

get_material_base_url <- function(base_url, lesson_id, release_tag) {
  res_url <-
    paste0(
      sub("/$", "", base_url),
      "/",
      lesson_id,
      "/releases/",
      release_tag,
      "/"
    )

  return(res_url)
}
