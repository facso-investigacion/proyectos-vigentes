

library(dplyr)
library(labelled)
library(haven)
library(readxl)

load("input/data_proyectos.rdata")
load("input/abstracts.rdata")
acad <- read_excel("input/acad.xlsx")

# Nombres sociales

archivo_out  <- "input/nombres_sociales.csv"

nombres_sociales <- acad %>%
  mutate(
    primer_nombre = sapply(strsplit(NOMBRES, "\\s+"), `[`, 1),
    nombre_social = paste(primer_nombre, PATERNO)
  ) %>%
  select(RUT, nombre_completo_paterno = PATERNO,
         nombre_completo_materno = MATERNO,
         nombre_completo_nombres = NOMBRES,
         nombre_social) %>%
  distinct(RUT, .keep_all = TRUE) %>%   # eliminar RUTs duplicados
  arrange(nombre_social)

# Guardar como CSV
write.csv(nombres_sociales, archivo_out, row.names = FALSE, fileEncoding = "UTF-8")


data_proyectos <- data_proyectos |>
  mutate(across(where(is.labelled), as_factor)) |> 
  filter(codigo_proyecto != "1220139")

proyectos_vigentes <- data_proyectos |> 
  filter(en_ejecucion == "Sí" & institucion != "FACSO" & investigador_responsable != "Externo")
  
consolidado <- consolidado |> 
  select("codigo_proyecto", 
         abstract  = "url (acceso)") |> 
  mutate(codigo_proyecto = as.character(codigo_proyecto))

proyectos_vigentes <- proyectos_vigentes |> 
  left_join(consolidado, by="codigo_proyecto")

# ==== Aplicar nombres sociales =============================================
nombres_sociales <- read.csv("input/nombres_sociales.csv",
                             stringsAsFactors = FALSE,
                             fileEncoding = "UTF-8")

aplicar_nombre_social <- function(rut, nombre_original) {
  if (is.na(rut) || is.na(nombre_original)) return(nombre_original)
  match <- nombres_sociales$nombre_social[nombres_sociales$RUT == rut]
  if (length(match) > 0 && !is.na(match[1])) return(match[1])
  return(nombre_original)
}

proyectos_vigentes <- proyectos_vigentes %>%
  rowwise() %>%
  mutate(
    investigador_responsable = aplicar_nombre_social(rut_ir,    investigador_responsable),
    coi_1 = aplicar_nombre_social(rut_coi_1, coi_1),
    coi_2 = aplicar_nombre_social(rut_coi_2, coi_2),
    coi_3 = aplicar_nombre_social(rut_coi_3, coi_3),
    coi_4 = aplicar_nombre_social(rut_coi_4, coi_4)
  ) %>%
  ungroup()
# ===========================================================================


# Exportar a CSV para que yo lo pueda leer
write.csv(proyectos_vigentes, "output/proyectos_vigentes.csv", row.names = FALSE)

