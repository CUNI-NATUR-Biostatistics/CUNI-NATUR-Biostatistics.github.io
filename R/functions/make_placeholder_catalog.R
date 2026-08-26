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
    offering <-
      read_utf8_yaml(path = year_config$offering)
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
          release_base_url = NULL,
          manifest = NULL
        )
    }

    list_years[[year_config$slug]] <-
      list(
        slug = year_config$slug,
        label = year_config$label,
        semester_label = offering$semester_label,
        semester_status = offering$semester_status,
        frozen = isTRUE(offering$frozen),
        content = offering$content,
        content_hashes = offering$content_hashes,
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
