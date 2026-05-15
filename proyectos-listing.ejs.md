```{=html}
<div class="proyectos-grid list">

<!-- Barra de filtros tipo dropdown -->
<div class="proyectos-filtros">
  <div class="filtro-dropdown" data-filter-field="fecha_inicio">
    <button type="button" class="filtro-btn">
      <span class="filtro-label">Año</span>
      <span class="filtro-caret">▾</span>
    </button>
    <div class="filtro-menu"></div>
  </div>

  <div class="filtro-dropdown" data-filter-field="concurso">
    <button type="button" class="filtro-btn">
      <span class="filtro-label">Concurso</span>
      <span class="filtro-caret">▾</span>
    </button>
    <div class="filtro-menu"></div>
  </div>

  <div class="filtro-dropdown" data-filter-field="departamento">
    <button type="button" class="filtro-btn">
      <span class="filtro-label">Departamento</span>
      <span class="filtro-caret">▾</span>
    </button>
    <div class="filtro-menu"></div>
  </div>

  <button type="button" class="filtro-reset">Limpiar filtros</button>
</div>

<!-- Encabezados clicables -->
<div class="proyecto-header">
  <button type="button" class="proyecto-header-col sort-button" data-sort-target="fecha_inicio">
    Año
    <span class="sort-indicator"></span>
  </button>
  <button type="button" class="proyecto-header-col sort-button" data-sort-target="author">
    Investigador/a Responsable
    <span class="sort-indicator"></span>
  </button>
  <button type="button" class="proyecto-header-col sort-button" data-sort-target="title">
    Proyecto
    <span class="sort-indicator"></span>
  </button>
</div>

<% for (const item of items) { %>

<div class="proyecto-card" <%= metadataAttrs(item) %>>

  <!-- Columna 1: año -->
  <div class="proyecto-anio">
    <% if (item.fecha_inicio || item.fecha_termino) { %>
    <span>
      <span class="listing-fecha_inicio"><%= item.fecha_inicio || "?" %></span>
      <span class="anio-separador"> - </span>
      <span class="listing-fecha_termino"><%= item.fecha_termino || "?" %></span>
    </span>
    <% } %>
  </div>

  <!-- Columna 2: autor -->
  <div class="proyecto-autor">
    <span class="listing-author"><%= item.author || "" %></span>
  </div>

  <!-- Columna 3: información del proyecto -->
  <div class="proyecto-info">

    <a href="<%- item.path %>" class="proyecto-titulo listing-title">
      <%= item.title %>
    </a>

    <% if (item.concurso) { %>
    <div class="proyecto-meta">
      <span class="listing-concurso"><%= item.concurso %></span>
    </div>
    <% } %>

    <% if (item.departamento) { %>
    <div class="proyecto-meta">
      <span class="listing-departamento">Departamento de <%= item.departamento %></span>
    </div>
    <% } %>

    <% if (item.coinvestigadores) { %>
    <div class="proyecto-meta">
      <span class="meta-label">Co-investigadores FACSO:</span>
      <span class="listing-coinvestigadores"><%= item.coinvestigadores %></span>
    </div>
    <% } %>

    <% if (item['url_abstract']) { %>
    <div class="proyecto-abstract-link">
      <a href="<%- item['url_abstract'] %>" target="_blank" rel="noopener">
        <i class="bi bi-file-text"></i> Ver abstract
      </a>
    </div>
    <% } %>

  </div><!-- /proyecto-info -->

</div><!-- /proyecto-card -->

<% } %>

</div><!-- /proyectos-grid -->
```