#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#              Make placeholder catalog
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

make_placeholder_catalog <- function(config) {
  list_years <- list()

  for (
    year_config in config$years
    ) {
    list_lessons <- list()
    for (
      lesson_config in config$lessons
      ) {
      list_lessons[[lesson_config$id]] <-
        list(
          id = lesson_config$id,
          title = lesson_config$title,
          subtitle = "",
          status = "preparing",
          release = NULL,
          release_year = NULL,
          material_base_url = NULL,
          manifest = NULL
        )
    }

    list_years[[year_config$slug]] <-
      list(
        slug = year_config$slug,
        label = year_config$label,
        frozen = FALSE,
        lessons = list_lessons
      )
  }

  res_catalog <-
    list(
      schema_version = 1L,
      generated_at = NULL,
      current_year = config$current_year,
      years = list_years
    )

  return(res_catalog)
}
