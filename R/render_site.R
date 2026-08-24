#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                    Render site
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

source("R/sync_brand.R")
source("R/build_site.R")
quarto::quarto_render()
