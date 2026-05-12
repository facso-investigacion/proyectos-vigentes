# =============================================================================
# generar_bibtex.R
# Genera un archivo .bib a partir de un CSV de proyectos de investigación
#
# Uso:
#   1. Ajusta los parámetros en la sección "CONFIGURACIÓN"
#   2. Ejecuta el script completo en R o RStudio
# =============================================================================


# ==== CONFIGURACIÓN ==========================================================

archivo_csv    <- "output/proyectos_vigentes.csv"   # Ruta al CSV de entrada
archivo_bib    <- "proyectos/proyectos.bib"        # Ruta al .bib de salida

# Si tu CSV tiene una columna llamada "abstract" con URLs, se incluirá
# automáticamente como campo url = {...} en cada entrada

# =============================================================================


# ==== FUNCIONES AUXILIARES ===================================================

#' Escapa caracteres especiales de LaTeX
clean_tex <- function(x) {
  if (is.na(x) || x == "") return("")
  x <- as.character(x)
  x <- gsub("&",  "\\\\&",  x)
  x <- gsub("%",  "\\\\%",  x)
  x <- gsub("#",  "\\\\#",  x)
  x <- gsub("_",  "\\\\_",  x)
  trimws(x)
}

#' Extrae el año de un valor numérico o de texto
extract_year <- function(x) {
  if (is.na(x) || x == "") return("")
  as.character(as.integer(as.numeric(x)))
}

#' Construye la clave BibTeX: ApellidoAÑO_codigo
make_key <- function(nombre, anio, codigo) {
  partes   <- strsplit(trimws(nombre), "\\s+")[[1]]
  apellido <- gsub("[^a-zA-Z]", "", tail(partes, 1))
  if (apellido == "") apellido <- "Unknown"
  codigo_clean <- gsub("[^a-zA-Z0-9]", "", codigo)
  paste0(apellido, anio, "_", codigo_clean)
}

#' Construye una entrada @techreport completa
make_entry <- function(row) {

  # Campos principales
  titulo   <- clean_tex(row[["titulo"]])
  autor    <- clean_tex(row[["investigador_responsable"]])
  departamento_ir <- clean_tex(row[["departamento_ir"]])
  anio     <- extract_year(row[["anio_concurso"]])
  concurso <- clean_tex(row[["concurso"]])
  codigo   <- clean_tex(row[["codigo_proyecto"]])

  # Co-investigadores → campo editor
  cois <- c(row[["coi_1"]], row[["coi_2"]], row[["coi_3"]], row[["coi_4"]])
  cois <- Filter(function(x) !is.na(x) && x != "", cois)
  cois <- sapply(cois, clean_tex)

  # Fechas y duración
  year_inicio <- extract_year(row[["fecha_inicio"]])
  year_fin    <- extract_year(row[["fecha_termino"]])
  duracion    <- ifelse(!is.na(row[["duracion"]]),
                        paste0(as.integer(row[["duracion"]]), " meses"), "")

  # Monto
  # monto  <- ifelse(!is.na(row[["monto_adjudicado"]]),
  #                  as.character(row[["monto_adjudicado"]]), "")
  # moneda <- clean_tex(row[["moneda"]])

  # Palabras clave
  palabras <- clean_tex(row[["palabras_claves"]])

  # URL del abstract (columna "abstract" en el CSV)
  url <- ""
  if ("abstract" %in% names(row) && !is.na(row[["abstract"]]) && row[["abstract"]] != "")
    url <- trimws(as.character(row[["abstract"]]))

  # Clave única
  key <- make_key(autor, anio, codigo)

  # Construcción de la entrada
  lines <- c(
    paste0("@techreport{", key, ","),
    paste0("  title        = {", titulo, "},"),
    paste0("  author       = {", autor, "},"),
    paste0("  institution  = {", departamento_ir, "},")
  )

  if (length(cois) > 0)
    lines <- c(lines, paste0("  editor       = {", paste(cois, collapse = " and "), "},"))

  if (anio != "")
    lines <- c(lines, paste0("  year         = {", anio, "},"))

  if (concurso != "")
    lines <- c(lines, paste0("  type         = {", concurso, "},"))

  if (codigo != "")
    lines <- c(lines, paste0("  number       = {", codigo, "},"))

  if (year_inicio != "")
    lines <- c(lines, paste0("  date-start   = {", year_inicio, "},"))

  if (year_fin != "")
    lines <- c(lines, paste0("  date-end     = {", year_fin, "},"))

  if (duracion != "")
    lines <- c(lines, paste0("  duration     = {", duracion, "},"))

  # if (monto != "")
  #   lines <- c(lines, paste0("  howpublished = {Monto adjudicado: ", monto, " ", moneda, "},"))

  if (palabras != "")
    lines <- c(lines, paste0("  keywords     = {", palabras, "},"))

  if (url != "")
    lines <- c(lines, paste0("  url          = {", url, "},"))

  lines <- c(lines, "}")
  paste(lines, collapse = "\n")
}


# ==== EJECUCIÓN ==============================================================

cat("Leyendo CSV:", archivo_csv, "\n")
df <- read.csv(archivo_csv, stringsAsFactors = FALSE, encoding = "UTF-8")

# Filtrar registros sin título
df <- df[!is.na(df$titulo) & df$titulo != "", ]
cat("Proyectos con título:", nrow(df), "\n")

# Informar cuántos tienen URL de abstract
if ("abstract" %in% names(df)) {
  n_url <- sum(!is.na(df$abstract) & df$abstract != "")
  cat("Proyectos con URL de abstract:", n_url, "\n")
}

# Generar entradas, resolviendo claves duplicadas
entradas      <- vector("character", nrow(df))
claves_usadas <- list()

for (i in seq_len(nrow(df))) {
  row     <- df[i, ]
  entrada <- make_entry(row)

  # Resolver duplicados de clave
  key_base <- make_key(
    clean_tex(row[["investigador_responsable"]]),
    extract_year(row[["anio_concurso"]]),
    clean_tex(row[["codigo_proyecto"]])
  )

  if (!is.null(claves_usadas[[key_base]])) {
    claves_usadas[[key_base]] <- claves_usadas[[key_base]] + 1
    key_nuevo <- paste0(key_base, "_", claves_usadas[[key_base]])
    entrada   <- sub(paste0("\\{", key_base, ","),
                     paste0("{", key_nuevo, ","), entrada, fixed = TRUE)
  } else {
    claves_usadas[[key_base]] <- 0
  }

  entradas[i] <- entrada
}

# Escribir archivo .bib
bib_content <- paste(entradas, collapse = "\n\n")
writeLines(bib_content, con = archivo_bib, useBytes = FALSE)

cat("Archivo generado:", archivo_bib, "\n")
cat("Total entradas:  ", length(entradas), "\n")
