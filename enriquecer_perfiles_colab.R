# =============================================================================
# enriquecer_perfiles_colab.R
#
# Cruza nombres_sociales.xlsx con perfiles_colab.csv y agrega columna url_colab.
# Hace matching tolerante (sin acentos, minúsculas, comparando primer nombre +
# apellido paterno).
#
# Después de correrlo, el XLSX resultante queda listo para editarse manualmente
# en casos donde el matching automático no haya funcionado.
#
# Uso:
#   Rscript enriquecer_perfiles_colab.R
# =============================================================================

library(dplyr)
library(stringi)
library(readxl)
library(writexl)

archivo_nombres   <- "input/nombres_sociales.xlsx"
archivo_perfiles  <- "input/perfiles_colab.csv"
archivo_salida    <- "input/nombres_sociales.xlsx"   # sobreescribe

# Función: normalizar nombre para matching
normalizar <- function(x) {
  x %>%
    as.character() %>%
    stri_trans_general("latin-ascii") %>%
    tolower() %>%
    gsub("[-]", " ", .) %>%       # guiones por espacios
    gsub("\\s+", " ", .) %>%      # múltiples espacios → uno
    trimws()
}

# Extraer primer nombre + primer apellido para matching
clave_match <- function(x) {
  x_norm <- normalizar(x)
  sapply(strsplit(x_norm, "\\s+"), function(partes) {
    if (length(partes) >= 2) {
      paste(partes[1], partes[2])
    } else {
      partes[1]
    }
  })
}

# ---- Leer datos ----
nombres   <- read_excel(archivo_nombres) %>%
  mutate(RUT = as.character(RUT))
perfiles  <- read.csv(archivo_perfiles, stringsAsFactors = FALSE, fileEncoding = "UTF-8")

# ---- Crear claves de matching ----
nombres$clave_match  <- clave_match(nombres$nombre_social)
perfiles$clave_match <- clave_match(perfiles$nombre_colab)

# ---- Cruzar ----
nombres_enriquecidos <- nombres %>%
  left_join(perfiles %>% select(clave_match, url_colab), by = "clave_match") %>%
  select(-clave_match)

# ---- Reportar ----
matches    <- sum(!is.na(nombres_enriquecidos$url_colab))
no_matches <- sum(is.na(nombres_enriquecidos$url_colab))
cat("Académicos con perfil Colab:    ", matches, "\n")
cat("Académicos sin perfil Colab:    ", no_matches, "\n")
cat("Perfiles Colab no cruzados:     ",
    sum(!perfiles$clave_match %in% nombres$clave_match), "\n\n")

# Mostrar académicos sin match (para revisión manual)
sin_match <- nombres_enriquecidos %>%
  filter(is.na(url_colab)) %>%
  select(RUT, nombre_social)
if (nrow(sin_match) > 0 && nrow(sin_match) < 50) {
  cat("Académicos sin perfil Colab encontrado:\n")
  print(sin_match)
}

# ---- Guardar ----
write_xlsx(nombres_enriquecidos, archivo_salida)
cat("\nArchivo actualizado:", archivo_salida, "\n")