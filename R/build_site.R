#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                 Build site sources
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

source("R/functions/read_utf8_yaml.R")
source("R/functions/read_course_config.R")
source("R/functions/make_placeholder_catalog.R")
source("R/functions/read_catalog.R")
source("R/functions/escape_html.R")
source("R/functions/escape_yaml_text.R")
source("R/functions/render_resource_link.R")
source("R/functions/get_public_resource_url.R")
source("R/functions/get_source_blob_url.R")
source("R/functions/format_release_date.R")
source("R/functions/render_supplementary_links.R")
source("R/functions/render_lesson_card.R")
source("R/functions/render_lesson_page.R")
source("R/functions/read_semester_fragment.R")
source(
  "R/functions/render_redirect_page.R",
  encoding = "UTF-8"
)
source(
  "R/functions/write_site_sources.R",
  encoding = "UTF-8"
)

config <-
  read_course_config()
catalog <-
  read_catalog(config = config)

write_site_sources(catalog = catalog)

for (
  generated_directory in c("semestry", "rok")
  ) {
  unlink(generated_directory, recursive = TRUE, force = TRUE)
  moved <-
    file.rename(
      from = file.path("_generated", generated_directory),
      to = generated_directory
    )
  if (!isTRUE(moved)) {
    cli::cli_abort(
      "Could not move generated sources into {.path {generated_directory}/}."
    )
  }
}
