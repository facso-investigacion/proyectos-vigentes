# =============================================================================
# proyectos2quarto.R
# Convierte el .bib de proyectos de investigación en archivos .qmd para Quarto
#
# Campos del .bib de proyectos:
#   title, author (IR), editor (co-investigadores), year, type (concurso),
#   number (código), date-start, date-end, duration, howpublished (monto),
#   keywords, url (abstract)
#
# Uso:
#   1. Ajusta los parámetros en la sección "CONFIGURACIÓN"
#   2. Ejecuta el script completo en R o RStudio:
#        source("proyectos2quarto.R")
# =============================================================================


# ==== CONFIGURACIÓN ==========================================================

archivo_bib <- "proyectos/proyectos.bib"          # Ruta al .bib generado por generar_bibtex.R
carpeta_out <- "proyectos/posts"        # Carpeta donde se crearán los .qmd
overwrite   <-  TRUE                  # TRUE para sobreescribir archivos existentes

# =============================================================================


# ==== DEPENDENCIAS ===========================================================

if (!require("pacman")) install.packages("pacman")
pacman::p_load(RefManageR, dplyr, stringr, stringi, tidyr)


# ==== FUNCIÓN PRINCIPAL ======================================================

proyectos_2_quarto <- function(bibfile, outfold, overwrite = FALSE) {

  # Crear carpeta de salida si no existe
  if (dir.exists(outfold)) {
    qmds_anteriores <- list.files(outfold, pattern = "\\.qmd$", full.names = TRUE)
    if (length(qmds_anteriores) > 0) {
      file.remove(qmds_anteriores)
      cat("Eliminados", length(qmds_anteriores), ".qmd anteriores\n")
    }
  } else {
    dir.create(outfold, recursive = TRUE)
  }


  # ---- Función auxiliar: invertir nombres (Nombre Apellido → Apellido, Nombre) ----
  invert_author_names <- function(author_string) {
    if (is.null(author_string) || is.na(author_string) || author_string == "")
      return(author_string)

    surname_particles <- c(
      "da", "das", "de", "del", "della", "delle", "dels", "der", "di", "do", "dos",
      "du", "el", "la", "las", "le", "los", "van", "von", "y", "san", "santa"
    )

    authors <- trimws(unlist(strsplit(author_string, "\\s+and\\s+", perl = TRUE)))

    authors <- vapply(authors, function(nm) {
      nm <- gsub("[{}]", "", nm)
      nm <- trimws(nm)
      if (grepl(",", nm, fixed = TRUE)) return(nm)

      parts <- unlist(strsplit(nm, "\\s+", perl = TRUE))
      if (length(parts) < 2) return(nm)

      idx <- length(parts)
      surname_idx <- idx
      while (idx > 1) {
        if (tolower(parts[idx - 1]) %in% surname_particles) {
          surname_idx <- idx - 1
          idx <- idx - 1
        } else break
      }
      surname    <- paste(parts[surname_idx:length(parts)], collapse = " ")
      given      <- paste(parts[seq_len(surname_idx - 1)], collapse = " ")
      paste0(surname, ", ", given)
    }, character(1))

    paste(authors, collapse = " and ")
  }


  # ---- Leer el .bib ----
  mypubs <- ReadBib(bibfile, check = "warn", .Encoding = "UTF-8") %>%
    as.data.frame()

  # Asegurar que existan todas las columnas necesarias
  needed_cols <- c(
    "title", "author", "editor", "year", "type", "number",
    "date-start", "date-end", "duration", "howpublished",
    "keywords", "url", "institution", "bibtype"
  )
  for (col in needed_cols) {
    if (!col %in% names(mypubs)) mypubs[[col]] <- NA_character_
  }

  # ---- Limpiar campos de texto ----

  # Eliminar backslashes residuales de LaTeX
  for (col in c("title", "author", "editor", "keywords", "howpublished", "url", "institution")) {
    mypubs[[col]] <- gsub("\\\\", "", mypubs[[col]])
  }

  # Escapar comillas dobles internas para YAML válido
  mypubs$title <- gsub('"', '\\"', mypubs$title, fixed = TRUE)

  # Formatear co-investigadores: "A and B and C" → "A, B & C"
  mypubs$editor <- gsub(" and ", ", ", mypubs$editor, fixed = TRUE)
  mypubs$editor <- stri_replace_last_fixed(mypubs$editor, ",", " &")

  # Formatear keywords para YAML: "A B C" → "A","B","C"  (separadas por espacios en el .bib)
  mypubs$keywords <- gsub(",", '","', mypubs$keywords)

  # Reemplazar NAs visibles por cadena vacía en campos de texto
  for (col in c("editor", "url", "keywords", "howpublished", "duration", "institution",
                "date-start", "date-end", "type", "number")) {
    mypubs[[col]] <- replace_na(as.character(mypubs[[col]]), "")
  }

  # Asignar categoría basada en el concurso (campo type)
  mypubs <- mypubs %>%
    mutate(
      categories = case_when(
        str_detect(tolower(type), "fondecyt regular")      ~ "Fondecyt Regular",
        str_detect(tolower(type), "iniciaci")              ~ "Fondecyt Iniciación",
        str_detect(tolower(type), "postdoc")               ~ "Fondecyt Postdoctorado",
        str_detect(tolower(type), "anillo")                ~ "Anillos",
        str_detect(tolower(type), "fpci|fortalecimiento")  ~ "FPCI",
        str_detect(tolower(type), "fondap")                ~ "FONDAP",
        str_detect(tolower(type), "millenium|milenio")     ~ "Núcleos Milenio",
        TRUE ~ "Proyecto de Investigación"
      )
    )


  # ---- Función que crea un .qmd por proyecto ----
  create_md <- function(x) {

    # Año para nombre de archivo y fecha
    anio <- ifelse(!is.na(x[["year"]]) && x[["year"]] != "", x[["year"]], "9999")

    # Nombre de archivo: YYYY_CodigoProyecto_PrimeraPalabra.qmd
    codigo_limpio <- gsub("[^a-zA-Z0-9]", "", x[["number"]])
    titulo_corto  <- x[["title"]] %>%
      str_replace_all(fixed(" "), "_") %>%
      str_remove_all(fixed(":")) %>%
      str_remove_all(fixed("?")) %>%
      str_remove_all(fixed("%")) %>%
      str_sub(1, 25)

    filename <- paste0(anio, "_", codigo_limpio, "_", titulo_corto, ".qmd")
    filepath <- file.path(outfold, filename)

    if (file.exists(filepath) && !overwrite) return(invisible(NULL))

    fileConn <- filepath

    # --- Abrir YAML ---
    write("---", fileConn)

    # Título
    write(paste0('title: "', x[["title"]], '"'), fileConn, append = TRUE)

    # Fecha (usa date-start si existe, si no usa year)
    fecha <- if (!is.na(x[["date-start"]]) && x[["date-start"]] != "") {
      paste0(x[["date-start"]], "-01-01")
    } else {
      paste0(anio, "-01-01")
    }
    write(paste0('date: "', fecha, '"'), fileConn, append = TRUE)

    # Investigador responsable (campo author)
    # author_inv   <- invert_author_names(x[["author"]])
    auth_clean   <- stri_trans_general(x[["author"]], "latin-ascii")
    auth_vec     <- trimws(unlist(strsplit(auth_clean, " and ", fixed = TRUE)))
    auth_display <- if (length(auth_vec) <= 1) {
      auth_vec
    } else if (length(auth_vec) == 2) {
      paste(auth_vec, collapse = " & ")
    } else {
      paste0(paste(auth_vec[-length(auth_vec)], collapse = "; "),
             " & ", auth_vec[length(auth_vec)])
    }
    write(paste0('author: "', auth_display, '"'), fileConn, append = TRUE)

    # Departamento del IR (campo institution)
    if (!is.na(x[["institution"]]) && x[["institution"]] != "")
      write(paste0('departamento: "' , x[["institution"]], '"'), fileConn, append = TRUE)

    # Co-investigadores (campo editor)
    if (!is.na(x[["editor"]]) && x[["editor"]] != "") {
      write(paste0('coinvestigadores: "', x[["editor"]], '"'), fileConn, append = TRUE)
    }

    # Categorías basadas en concurso
    write(paste0('categories: ["', x[["categories"]], '"]'), fileConn, append = TRUE)

    # Keywords
    if (!is.na(x[["keywords"]]) && x[["keywords"]] != "") {
      write(paste0('keywords: ["', x[["keywords"]], '"]'), fileConn, append = TRUE)
    }

    # --- Bloque de detalles del proyecto ---
    # Concurso y código
    if (!is.na(x[["type"]]) && x[["type"]] != "")
      write(paste0('concurso: "', x[["type"]], '"'), fileConn, append = TRUE)

    if (!is.na(x[["number"]]) && x[["number"]] != "")
      write(paste0('codigo_proyecto: "', x[["number"]], '"'), fileConn, append = TRUE)

    # Fechas
    if (!is.na(x[["date-start"]]) && x[["date-start"]] != "")
      write(paste0('fecha_inicio: "', x[["date-start"]], '"'), fileConn, append = TRUE)

    if (!is.na(x[["date-end"]]) && x[["date-end"]] != "")
      write(paste0('fecha_termino: "', x[["date-end"]], '"'), fileConn, append = TRUE)

    if (!is.na(x[["duration"]]) && x[["duration"]] != "")
      write(paste0('duracion: "', x[["duration"]], '"'), fileConn, append = TRUE)

    # Monto
    if (!is.na(x[["howpublished"]]) && x[["howpublished"]] != "")
      write(paste0('financiamiento: "', x[["howpublished"]], '"'), fileConn, append = TRUE)

    # URL abstract
    if (!is.na(x[["url"]]) && x[["url"]] != "")
      write(paste0('url_abstract: "', x[["url"]], '"'), fileConn, append = TRUE)

    # Bloque about con link al abstract si existe
    write("about:", fileConn, append = TRUE)
    write("  template: marquee", fileConn, append = TRUE)
    if (!is.na(x[["url"]]) && x[["url"]] != "") {
      write("  links:", fileConn, append = TRUE)
      write("    - icon: file-text", fileConn, append = TRUE)
      write(paste0("      href: ", x[["url"]]), fileConn, append = TRUE)
    }

    # --- Cerrar YAML ---
    write("---", fileConn, append = TRUE)

    # --- Cuerpo: callout "Cómo citar" ---
    # Preparar autores para cita
    # authors_cita <- stri_trans_general(auth_clean, "latin-ascii")
    # authors_vec  <- trimws(unlist(strsplit(authors_cita, " and ", fixed = TRUE)))
    # authors_cita_fmt <- if (length(authors_vec) <= 1) {
    #   authors_vec
    # } else if (length(authors_vec) == 2) {
    #   paste(authors_vec, collapse = " & ")
    # } else {
    #   paste0(paste(authors_vec[-length(authors_vec)], collapse = "; "),
    #          " & ", authors_vec[length(authors_vec)])
    # }
    # 
    # titulo_cita  <- gsub("\\\\", "", x[["title"]])
    # concurso_cita <- ifelse(!is.na(x[["type"]]) && x[["type"]] != "",
    #                         x[["type"]], "")
    # codigo_cita  <- ifelse(!is.na(x[["number"]]) && x[["number"]] != "",
    #                        paste0(" (", x[["number"]], ")"), "")
    # 
    # citation_text <- paste0(
    #   authors_cita_fmt, " (", anio, "). *", titulo_cita, "*. ",
    #   concurso_cita, codigo_cita, "."
    # )
    # 
    # write('\n\n::: {.callout-note title="Cómo citar este proyecto"}\n',
    #       fileConn, append = TRUE)
    # write(citation_text, fileConn, append = TRUE)
    # write("\n:::\n", fileConn, append = TRUE)
  }

  # Aplicar sobre todas las filas
  cat("Generando archivos .qmd en:", outfold, "\n")
  apply(mypubs, FUN = function(x) create_md(x), MARGIN = 1)
  cat("Listo. Total procesados:", nrow(mypubs), "\n")
}


# ==== EJECUCIÓN ==============================================================

proyectos_2_quarto(
  bibfile  = archivo_bib,
  outfold  = carpeta_out,
  overwrite = overwrite
)
