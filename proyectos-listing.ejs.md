```{=html}
<div class="proyectos-grid list">

<!-- Encabezados clicables para ordenar -->
<div class="proyecto-header">
  <button type="button" class="proyecto-header-col sort-button" data-sort-target="author">
    Investigador/a Responsable
    <span class="sort-indicator"></span>
  </button>
  <button type="button" class="proyecto-header-col sort-button" data-sort-target="fecha_inicio">
    Proyecto
    <span class="sort-indicator"></span>
  </button>
</div>

<% for (const item of items) { %>

<div class="proyecto-card" <%= metadataAttrs(item) %>>

  <!-- Columna izquierda: autor -->
  <div class="proyecto-autor">
    <span class="listing-author"><%= item.author || "" %></span>
  </div>

  <!-- Columna derecha: información visible -->
  <div class="proyecto-info">

    <!-- Título con link -->
    <a href="<%- item.path %>" class="proyecto-titulo listing-title">
      <%= item.title %>
    </a>

    <!-- Año (inicio-término) -->
    <% if (item.fecha_inicio || item.fecha_termino) { %>
    <div class="proyecto-meta">
      <span class="listing departamento">
        <%= item.fecha_inicio || "?" %> - <%= item.fecha_termino || "?" %>
      </span>
    </div>
    <% } %>

    <!-- Concurso -->
    <% if (item.concurso) { %>
    <div class="proyecto-meta">
      <span class="listing departamento"><%= item.concurso %></span>
    </div>
    <% } %>

    <!-- Departamento -->
    <% if (item.departamento) { %>
    <div class="proyecto-meta">
      <span class="listing-departamento">Departamento de <%= item.departamento %></span>
    </div>
    <% } %>

    <!-- Co-investigadores FACSO -->
    <% if (item.coinvestigadores) { %>
    <div class="proyecto-meta">
      <span class="meta-label">Co-investigadores FACSO:</span>
      <span class="listing-coinvestigadores"><%= item.coinvestigadores %></span>
    </div>
    <% } %>

    <!-- Link al abstract -->
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
