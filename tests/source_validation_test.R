# Static syntax and configuration checks for the HUB sources.

source("R/functions/read_utf8_yaml.R")

r_files <-
  c(
    "R/build_site.R",
    "R/freeze_offering.R",
    "R/sync_catalog.R",
    list.files(
      path = "R/functions",
      pattern = "[.]R$",
      full.names = TRUE
    ),
    list.files(
      path = "tests",
      pattern = "[.]R$",
      full.names = TRUE
    )
  )

invisible(
  lapply(
    r_files,
    function(path) {
      parse(file = path, encoding = "UTF-8")
    }
  )
)

quarto_config <- read_utf8_yaml("_quarto.yml")
course_config <- read_utf8_yaml("config/course.yml")
offering <- read_utf8_yaml("offerings/2026-27.yml")

stopifnot(
  identical(quarto_config$website$title, "Biostatistika"),
  identical(course_config$current_year, "2026-27"),
  identical(
    course_config$course_title,
    "Biostatistika a pl\u00e1nov\u00e1n\u00ed ekologick\u00fdch pokus\u016f"
  ),
  identical(
    offering$semester_label,
    "Zimn\u00ed semestr 2026/27"
  ),
  identical(offering$semester_status, "preliminary"),
  all(
    c("schedule", "assessment", "team") %in%
      names(offering$content)
  )
)

message("HUB R syntax and YAML validation passed.")
