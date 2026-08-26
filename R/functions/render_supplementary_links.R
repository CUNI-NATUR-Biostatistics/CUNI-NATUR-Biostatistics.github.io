#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#          Render supplementary links
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

render_supplementary_links <- function(
  lesson,
  channel = c("current", "archive")
) {
  channel <- match.arg(channel)
  vec_links <- character()

  list_groups <-
    list(
      exercises = "R",
      data = "Data",
      extras = "P\u0159\u00edloha"
    )

  for (
    group_name in names(list_groups)
    ) {
    entries <- lesson$manifest$resources[[group_name]]
    if (is.null(entries) || length(entries) == 0L) {
      next
    }

    for (
      entry in entries
      ) {
      label <-
        paste0(
          list_groups[[group_name]],
          ": ",
          entry$label
        )
      vec_links <-
        c(
          vec_links,
          render_resource_link(
            label = label,
            href = get_public_resource_url(
              lesson = lesson,
              resource = entry,
              channel = channel
            ),
            download = TRUE
          )
        )
    }
  }

  return(vec_links)
}
