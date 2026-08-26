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

  for (
    year_config in config$years
    ) {
    year <- catalog$years[[year_config$slug]]
    if (is.null(year)) {
      next
    }
    offering <-
      read_utf8_yaml(path = year_config$offering)
    year$semester_label <- offering$semester_label
    year$semester_status <- offering$semester_status
    year$frozen <- isTRUE(offering$frozen)
    year$content <- offering$content
    year$content_hashes <- offering$content_hashes
    catalog$years[[year_config$slug]] <- year
  }

  return(catalog)
}
