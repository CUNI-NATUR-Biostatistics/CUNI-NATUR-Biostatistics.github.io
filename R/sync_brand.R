#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Synchronize branding
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

brand_source_files <-
  c(
    "theme/brand_theme.scss",
    "theme/fonts-include.html",
    "assets/logo/biostatistika-icon.svg",
    "assets/logo/biostatistika-icon-reversed.svg"
  )

brand_target_files <-
  c(
    "brand_theme.scss",
    "fonts-include.html",
    "logo/biostatistika-icon.svg",
    "logo/biostatistika-icon-reversed.svg"
  )

brand_target_root <-
  file.path("assets", "brand")
brand_target_paths <-
  file.path(brand_target_root, brand_target_files)

for (
  target_directory in unique(dirname(brand_target_paths))
  ) {
  dir.create(
    path = target_directory,
    recursive = TRUE,
    showWarnings = FALSE
  )
}

local_brand_root <-
  file.path("..", "_brand")
local_brand_paths <-
  file.path(local_brand_root, brand_source_files)
remote_brand_root <-
  paste0(
    "https://raw.githubusercontent.com/",
    "CUNI-NATUR-Biostatistics/_brand/main"
  )

brand_stage_paths <-
  file.path(
    dirname(brand_target_paths),
    paste0(".", basename(brand_target_paths), ".tmp")
  )
unlink(
  x = brand_stage_paths,
  force = TRUE
)
on.exit(
  unlink(
    x = brand_stage_paths,
    force = TRUE
  ),
  add = TRUE
)

brand_source <-
  if (all(file.exists(local_brand_paths))) {
    copied <-
      file.copy(
        from = local_brand_paths,
        to = brand_stage_paths,
        overwrite = TRUE
      )
    if (!all(copied)) {
      cli::cli_abort("Could not stage the local canonical brand files.")
    }
    "local sibling _brand repository"
  } else {
    downloaded <-
      logical(length(brand_source_files))

    for (
      file_index in seq_along(brand_source_files)
      ) {
      downloaded[[file_index]] <-
        tryCatch(
          expr = {
            download.file(
              url = paste(
                remote_brand_root,
                brand_source_files[[file_index]],
                sep = "/"
              ),
              destfile = brand_stage_paths[[file_index]],
              mode = "wb",
              quiet = TRUE
            )
            TRUE
          },
          error = function(error) FALSE
        )
    }

    if (!all(downloaded)) {
      if (!all(file.exists(brand_target_paths))) {
        cli::cli_abort(
          paste(
            "Canonical branding could not be downloaded and the committed",
            "fallback is incomplete."
          )
        )
      }
      cli::cli_warn(
        paste(
          "Canonical branding could not be synchronized; using the",
          "committed fallback."
        )
      )
      "committed fallback"
    } else {
      "canonical _brand repository on GitHub"
    }
  }

if (brand_source != "committed fallback") {
  copied <-
    file.copy(
      from = brand_stage_paths,
      to = brand_target_paths,
      overwrite = TRUE
    )
  if (!all(copied)) {
    cli::cli_abort("Could not update the committed brand assets.")
  }

  synchronized <-
    unname(tools::md5sum(brand_stage_paths)) ==
      unname(tools::md5sum(brand_target_paths))
  if (!all(synchronized)) {
    cli::cli_abort("The synchronized brand assets failed verification.")
  }
}

theme_text <-
  paste(
    readLines(con = brand_target_paths[[1]]),
    collapse = "\n"
  )
fonts_text <-
  paste(
    readLines(con = brand_target_paths[[2]]),
    collapse = "\n"
  )
icon_text <-
  paste(
    readLines(con = brand_target_paths[[3]]),
    collapse = "\n"
  )

required_signatures <-
  c(
    "#5D2890",
    "#F4F1EC",
    "Inter",
    "Source Sans 3",
    "JetBrains Mono"
  )
brand_text <-
  paste(theme_text, fonts_text)
has_signature <-
  logical(length(required_signatures))

for (
  signature_index in seq_along(required_signatures)
  ) {
  has_signature[[signature_index]] <-
    grepl(
      pattern = required_signatures[[signature_index]],
      x = brand_text,
      fixed = TRUE
    )
}

if (!all(has_signature)) {
  cli::cli_abort(
    paste(
      "The synchronized files do not match the course",
      "brand contract."
    )
  )
}

if (
  !grepl(
    pattern = "Biostatistika course icon",
    x = icon_text,
    fixed = TRUE
  )
) {
  cli::cli_abort("The synchronized course icon failed verification.")
}

unlink(
  x = brand_stage_paths,
  force = TRUE
)
cli::cli_inform(paste("Brand source:", brand_source))
