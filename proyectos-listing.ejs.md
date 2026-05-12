```{=html}
<div class="proyectos-grid list">

<!-- Encabezados de columna -->
<div class="proyecto-header">
  <div class="proyecto-header-col">Investigador/a Responsable</div>
  <div class="proyecto-header-col">Proyecto</div>
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

    <!-- Año y concurso -->
    
    
      <% if (item.date) { %>
      <div class="proyecto-meta">
      <span class="listing departamento"><%= new Date(item.date).getFullYear() %></span>
      </div>
      <% } %>
      
      
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
