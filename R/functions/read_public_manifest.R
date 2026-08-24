#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Read public manifest
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

read_public_manifest <- function(url) {
  res_manifest <-
    tryCatch(
      expr = {
        connection <-
          url(
            description = url,
            open = "rb"
          )
        on.exit(close(connection), add = TRUE)
        jsonlite::fromJSON(
          txt = connection,
          simplifyVector = FALSE
        )
      },
      error = function(condition) {
        NULL
      }
    )

  return(res_manifest)
}
