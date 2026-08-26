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

get_public_resource_url <- function(
  lesson,
  resource,
  channel = c("current", "archive")
) {
  channel <- match.arg(channel)
  base_url <- lesson$material_base_url
  if (identical(channel, "archive")) {
    base_url <- lesson$release_base_url
  }

  res_url <-
    paste0(
      base_url,
      resource$href
    )

  return(res_url)
}
