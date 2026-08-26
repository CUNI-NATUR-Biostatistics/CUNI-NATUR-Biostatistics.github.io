#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#               Read semester fragment
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

read_semester_fragment <- function(path, expected_hash = NULL) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    cli::cli_abort("Semester content path must be one non-empty string.")
  }

  project_root <-
    normalizePath(
      path = ".",
      winslash = "/",
      mustWork = TRUE
    )
  fragment_path <-
    normalizePath(
      path = path,
      winslash = "/",
      mustWork = TRUE
    )

  root_prefix <- paste0(tolower(project_root), "/")
  if (!startsWith(tolower(fragment_path), root_prefix)) {
    cli::cli_abort("Semester content must stay inside the HUB repository.")
  }

  first_bytes <-
    readBin(
      con = fragment_path,
      what = "raw",
      n = 3L
    )
  if (
    length(first_bytes) == 3L &&
      identical(as.integer(first_bytes), c(239L, 187L, 191L))
  ) {
    cli::cli_abort(
      "Semester content file {.path {path}} must use UTF-8 without BOM."
    )
  }

  content <-
    readLines(
      con = fragment_path,
      encoding = "UTF-8",
      warn = FALSE
    )
  if (any(grepl("\ufffd", content, fixed = TRUE))) {
    cli::cli_abort(
      "Semester content file {.path {path}} contains replacement characters."
    )
  }

  if (!is.null(expected_hash)) {
    actual_hash <- unname(tools::md5sum(fragment_path))
    if (!identical(actual_hash, expected_hash)) {
      cli::cli_abort(
        paste0(
          "Frozen semester content {.path {path}} changed after freezing. ",
          "Create a new semester instead of editing the snapshot."
        )
      )
    }
  }

  return(content)
}
