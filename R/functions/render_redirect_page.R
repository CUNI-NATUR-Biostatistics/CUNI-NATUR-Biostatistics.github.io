#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Render redirect page
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

render_redirect_page <- function(title, target) {
  c(
    "---",
    paste0("title: \"", escape_yaml_text(title), "\""),
    "page-layout: full",
    "---",
    "",
    paste0(
      "<script>window.location.replace(\"",
      target,
      "\");</script>"
    ),
    "",
    paste0(
      paste0(
        "Tato adresa byla nahrazena. Pokra\u010dujte na ",
        "[novou str\u00e1nku]("
      ),
      target,
      ")."
    )
  )
}
