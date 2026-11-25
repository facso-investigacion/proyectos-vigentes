

library(dplyr)
library(labelled)
library(haven)
library(readxl)
library(writexl)

load("input/data_proyectos.rdata")
load("input/abstracts.rdata")
# acad <- read_excel("input/acad.xlsx")
# 
# # Nombres sociales
# 
# archivo_out  <- "input/nombres_sociales.xlsx"
# 
# nombres_sociales <- acad %>%
#   mutate(
#     primer_nombre = sapply(strsplit(NOMBRES, "\\s+"), `[`, 1),
#     nombre_social = paste(primer_nombre, PATERNO)
#   ) %>%
#   select(RUT, nombre_completo_paterno = PATERNO,
#          nombre_completo_materno = MATERNO,
#          nombre_completo_nombres = NOMBRES,
#          nombre_social) %>%
#   distinct(RUT, .keep_all = TRUE) %>%   # eliminar RUTs duplicados
#   arrange(nombre_social)
# 
# # Guardar como CSV
# write_xlsx(nombres_sociales, archivo_out)


data_proyectos <- data_proyectos |>
  mutate(across(where(is.labelled), as_factor)) |> 
  filter(codigo_proyecto != "1220139")

proyectos_vigentes <- data_proyectos |> 
  filter(en_ejecucion == "Sí" & institucion != "FACSO" & !is.na(rut_ir))

proyectos_vigentes_coi <- data_proyectos |> 
  filter(en_ejecucion == "Sí" & institucion != "FACSO" & is.na(rut_ir))
  
consolidado <- consolidado |> 
  select("codigo_proyecto", 
         abstract  = "url (acceso)") |> 
  mutate(codigo_proyecto = as.character(codigo_proyecto))

proyectos_vigentes <- proyectos_vigentes |> 
  left_join(consolidado, by="codigo_proyecto")

# ==== Aplicar nombres sociales =============================================
nombres_sociales <- read_excel("input/nombres_sociales.xlsx")



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

write_xlsx(proyectos_vigentes_coi, "output/proyectos_vigentes_cois.xlsx")


# =================================================================================== #

# COIS proyectos vigentes (IR externo a FACSO, con co-investigadores/as FACSO)

# El IR es externo, por lo que no tiene departamento: se usa el de los/as
# co-investigadores/as, tomado de su proyecto más reciente como IR.
deptos <- data_proyectos |>
  mutate(across(c(rut_ir, departamento_ir), as.character)) |>
  filter(!is.na(rut_ir), !is.na(departamento_ir)) |>
  arrange(desc(as.numeric(as.character(anio_concurso)))) |>
  distinct(rut_ir, .keep_all = TRUE)

buscar_depto <- function(...) {
  ruts <- na.omit(as.character(c(...)))
  d    <- unique(na.omit(deptos$departamento_ir[match(ruts, deptos$rut_ir)]))
  if (length(d) == 0) NA_character_ else paste(d, collapse = " / ")
}

# Se exportan solo las columnas que usa la página (sin RUT)
cois_pagina <- proyectos_vigentes_coi |>
  left_join(consolidado, by = "codigo_proyecto") |>
  rowwise() |>
  mutate(
    departamento_ir = buscar_depto(rut_coi_1, rut_coi_2, rut_coi_3, rut_coi_4),
    coi_1 = aplicar_nombre_social(rut_coi_1, coi_1),
    coi_2 = aplicar_nombre_social(rut_coi_2, coi_2),
    coi_3 = aplicar_nombre_social(rut_coi_3, coi_3),
    coi_4 = aplicar_nombre_social(rut_coi_4, coi_4)
  ) |>
  ungroup() |>
  select(codigo_proyecto, titulo, institucion, concurso, investigador_responsable,
         departamento_ir, duracion, anio_concurso, fecha_inicio, fecha_termino,
         palabras_claves, coi_1, coi_2, coi_3, coi_4, abstract)

write.csv(cois_pagina, "output/proyectos_vigentes_cois.csv", row.names = FALSE)
