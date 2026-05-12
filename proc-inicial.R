load("input/data_proyectos.rdata")
load("input/abstracts.rdata")

library(dplyr)
library(labelled)
library(haven)


data_proyectos <- data_proyectos |>
  mutate(across(where(is.labelled), as_factor))

proyectos_vigentes <- data_proyectos |> 
  filter(en_ejecucion == "Sí" & institucion != "FACSO" & investigador_responsable != "Externo")
  
consolidado <- consolidado |> 
  select("codigo_proyecto", 
         abstract  = "url (acceso)") |> 
  mutate(codigo_proyecto = as.character(codigo_proyecto))

proyectos_vigentes <- left_join(proyectos_vigentes, consolidado, by="codigo_proyecto")


# Exportar a CSV para que yo lo pueda leer
write.csv(proyectos_vigentes, "output/proyectos_vigentes.csv", row.names = FALSE)

