#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                    Read catalog
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

read_catalog <- function(config, path = "data/catalog.json") {
  catalog <-
    jsonlite::fromJSON(
      txt = path,
      simplifyVector = FALSE
    )

  if (length(catalog$years) == 0L) {
    catalog <-
      make_placeholder_catalog(config = config)
  }

  return(catalog)
}
