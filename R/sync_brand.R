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

brand_files <-
  c(
    "brand_theme.scss",
    "fonts-include.html"
  )

brand_target <-
  file.path("assets", "brand")
dir.create(brand_target, recursive = TRUE, showWarnings = FALSE)

local_brand <-
  file.path("..", "_brand", "theme")
remote_brand <-
  paste0(
    "https://raw.githubusercontent.com/",
    "CUNI-NATUR-Biostatistics/_brand/main/theme"
  )

brand_stage <-
  file.path(brand_target, paste0(".", brand_files, ".tmp"))
unlink(brand_stage, force = TRUE)
on.exit(unlink(brand_stage, force = TRUE), add = TRUE)

brand_source <-
  if (all(file.exists(file.path(local_brand, brand_files)))) {
    copied <-
      file.copy(
        from = file.path(local_brand, brand_files),
        to = brand_stage,
        overwrite = TRUE
      )
    if (!all(copied)) {
      cli::cli_abort("Could not stage the local canonical brand files.")
    }
    "local sibling _brand repository"
  } else {
    downloaded <-
      vapply(
        brand_files,
        function(file_name) {
          tryCatch(
            {
              utils::download.file(
                url = paste(remote_brand, file_name, sep = "/"),
                destfile = brand_stage[[which(brand_files == file_name)]],
                mode = "wb",
                quiet = TRUE
              )
              TRUE
            },
            error = function(error) FALSE
          )
        },
        logical(1)
      )

    if (!all(downloaded)) {
      cached <-
        file.path(brand_target, brand_files)
      if (!all(file.exists(cached))) {
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
  staged <-
    brand_stage
  copied <-
    file.copy(
      from = staged,
      to = file.path(brand_target, brand_files),
      overwrite = TRUE
    )
  if (!all(copied)) {
    cli::cli_abort("Could not update the committed brand assets.")
  }

  synchronized <-
    unname(tools::md5sum(staged)) ==
      unname(tools::md5sum(file.path(brand_target, brand_files)))
  if (!all(synchronized)) {
    cli::cli_abort("The synchronized brand assets failed verification.")
  }
}

theme_text <-
  paste(readLines(file.path(brand_target, brand_files[[1]])), collapse = "\n")
fonts_text <-
  paste(readLines(file.path(brand_target, brand_files[[2]])), collapse = "\n")

required_signatures <-
  c("#5D2890", "#F4F1EC", "Inter", "Source Sans 3", "JetBrains Mono")
brand_text <-
  paste(theme_text, fonts_text)
has_signature <-
  vapply(
    required_signatures,
    grepl,
    logical(1),
    x = brand_text,
    fixed = TRUE
  )
if (!all(has_signature)) {
  cli::cli_abort(
    paste(
      "The synchronized files do not match the course",
      "brand contract."
    )
  )
}

unlink(brand_stage, force = TRUE)
cli::cli_inform(paste("Brand source:", brand_source))
