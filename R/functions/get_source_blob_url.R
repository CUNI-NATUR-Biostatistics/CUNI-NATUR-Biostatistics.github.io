#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Get source blob URL
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

get_source_blob_url <- function(lesson, resource) {
  repository <- lesson$manifest$repository
  res_url <-
    paste0(
      "https://github.com/",
      repository,
      "/blob/",
      lesson$release,
      "/",
      resource$source_path
    )

  return(res_url)
}
