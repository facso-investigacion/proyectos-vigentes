-- ultima-actualizacion.lua
-- Shortcode {{< ultima-actualizacion >}}: fecha del último commit que modificó
-- los datos de origen (no la fecha de renderizado del sitio).

local ARCHIVO_DATOS = "input/data_proyectos.rdata"

local MESES = {
  "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
  "agosto", "septiembre", "octubre", "noviembre", "diciembre"
}

local function fecha_datos()
  local raiz = quarto.project.directory or "."
  local cmd = 'git -C "' .. raiz .. '" log -1 --date=short-local --format=%cd -- ' .. ARCHIVO_DATOS
  local proceso = io.popen(cmd)
  if not proceso then return nil end
  local salida = proceso:read("*a") or ""
  proceso:close()

  local anio, mes, dia = salida:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if not anio then return nil end
  return string.format("%d de %s de %s", tonumber(dia), MESES[tonumber(mes)], anio)
end

return {
  ["ultima-actualizacion"] = function()
    local fecha = fecha_datos()
    if not fecha then
      quarto.log.warning("No se pudo obtener la fecha de " .. ARCHIVO_DATOS .. " desde git.")
      fecha = "fecha no disponible"
    end
    return pandoc.Str(fecha)
  end
}
