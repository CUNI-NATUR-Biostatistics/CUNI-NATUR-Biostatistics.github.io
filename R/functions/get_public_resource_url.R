#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#             Get public resource URL
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

get_public_resource_url <- function(lesson, resource) {
  res_url <-
    paste0(
      lesson$material_base_url,
      resource$href
    )

  return(res_url)
}
