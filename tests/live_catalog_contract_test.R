# Read-only live check of lesson manifest and HUB link contracts.

source("R/functions/read_utf8_yaml.R")
source("R/functions/read_course_config.R")
source("R/functions/read_public_manifest.R")
source("R/functions/validate_public_manifest.R")
source("R/functions/get_manifest_url.R")
source("R/functions/get_material_base_url.R")
source("R/functions/build_catalog.R")
source("R/functions/escape_html.R")
source("R/functions/render_resource_link.R")
source("R/functions/get_public_resource_url.R")
source("R/functions/format_release_date.R")
source("R/functions/render_supplementary_links.R")
source("R/functions/render_lesson_card.R")

config <- read_course_config()
catalog <- build_catalog(config)
l01 <- catalog$years[[config$current_year]]$lessons$L01

stopifnot(
  identical(l01$status, "published"),
  !is.null(l01$release)
)

current_card <-
  render_lesson_card(
    lesson = l01,
    year_slug = config$current_year,
    channel = "current"
  )
archive_card <-
  render_lesson_card(
    lesson = l01,
    year_slug = config$current_year,
    channel = "archive"
  )

stopifnot(
  grepl("/L01/current/", current_card, fixed = TRUE),
  grepl("/tree/main", current_card, fixed = TRUE),
  grepl(
    paste0("/L01/releases/", l01$release, "/"),
    archive_card,
    fixed = TRUE
  ),
  grepl(
    paste0("/tree/", l01$release),
    archive_card,
    fixed = TRUE
  ),
  grepl("bi bi-book", current_card, fixed = TRUE),
  grepl("bi bi-easel", current_card, fixed = TRUE),
  grepl("bi bi-file-earmark-pdf", current_card, fixed = TRUE),
  grepl("bi bi-file-earmark-code", current_card, fixed = TRUE),
  grepl("bi bi-github", current_card, fixed = TRUE),
  grepl("bi bi-book", archive_card, fixed = TRUE)
)

message("Live L01 manifest and current/archive link contracts passed.")
