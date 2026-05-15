// proyectos-sort.js
// Sort manual del DOM + filtros tipo dropdown

document.addEventListener('DOMContentLoaded', function() {

  // ============================================================
  // ESTADO GLOBAL
  // ============================================================
  var sortState = { target: null, dir: null };
  var filterState = {};  // ej: { departamento: ['Sociología'], concurso: ['Iniciación'] }

  // ============================================================
  // UTILIDADES
  // ============================================================
  function getFieldValue(card, field) {
    var el = card.querySelector('.listing-' + field);
    if (!el) return '';
    return el.textContent.trim();
  }

  // ============================================================
  // SORT
  // ============================================================
  function sortCards(target, dir) {
    var grid = document.querySelector('.proyectos-grid');
    if (!grid) return;
    var cards = Array.from(grid.querySelectorAll('.proyecto-card'));
    if (cards.length === 0) return;

    cards.sort(function(a, b) {
      var va = getFieldValue(a, target).toLowerCase();
      var vb = getFieldValue(b, target).toLowerCase();
      var na = parseFloat(va);
      var nb = parseFloat(vb);
      if (!isNaN(na) && !isNaN(nb)) {
        return dir === 'asc' ? na - nb : nb - na;
      }
      if (va < vb) return dir === 'asc' ? -1 : 1;
      if (va > vb) return dir === 'asc' ?  1 : -1;
      return 0;
    });
    cards.forEach(function(c) { grid.appendChild(c); });
  }

  function handleSortClick(target, btn) {
    var newDir;
    if (sortState.target === target) {
      newDir = sortState.dir === 'desc' ? 'asc' : 'desc';
    } else {
      newDir = 'desc';
    }
    sortState = { target: target, dir: newDir };
    sortCards(target, newDir);

    document.querySelectorAll('.sort-button').forEach(function(b) {
      var ind = b.querySelector('.sort-indicator');
      if (ind) ind.textContent = '';
    });
    var ind = btn.querySelector('.sort-indicator');
    if (ind) ind.textContent = newDir === 'asc' ? ' ▲' : ' ▼';
  }

  // ============================================================
  // FILTROS DROPDOWN
  // ============================================================
  function getUniqueValues(field) {
    var cards = document.querySelectorAll('.proyecto-card');
    var values = {};
    cards.forEach(function(card) {
      var val = getFieldValue(card, field);
      if (val) values[val] = true;
    });
    return Object.keys(values).sort();
  }

  function buildDropdown(dropdown) {
    var field = dropdown.dataset.filterField;
    var menu = dropdown.querySelector('.filtro-menu');
    var values = getUniqueValues(field);

    menu.innerHTML = '';
    values.forEach(function(val) {
      var label = document.createElement('label');
      label.className = 'filtro-opcion';

      var checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.value = val;
      checkbox.addEventListener('change', function() {
        toggleFilter(field, val, checkbox.checked);
        updateButtonLabel(dropdown);
      });

      var text = document.createElement('span');
      text.textContent = val;

      label.appendChild(checkbox);
      label.appendChild(text);
      menu.appendChild(label);
    });
  }

  function toggleFilter(field, value, checked) {
    if (!filterState[field]) filterState[field] = [];
    if (checked) {
      if (filterState[field].indexOf(value) === -1) {
        filterState[field].push(value);
      }
    } else {
      filterState[field] = filterState[field].filter(function(v) { return v !== value; });
      if (filterState[field].length === 0) delete filterState[field];
    }
    applyFilters();
  }

  function applyFilters() {
    var cards = document.querySelectorAll('.proyecto-card');
    cards.forEach(function(card) {
      var visible = true;
      Object.keys(filterState).forEach(function(field) {
        var selected = filterState[field];
        if (selected.length === 0) return;
        var cardValue = getFieldValue(card, field);
        if (selected.indexOf(cardValue) === -1) visible = false;
      });
      card.style.display = visible ? '' : 'none';
    });
  }

  function updateButtonLabel(dropdown) {
    var field = dropdown.dataset.filterField;
    var btn = dropdown.querySelector('.filtro-btn .filtro-label');
    var fieldNames = {
      fecha_inicio: 'Año',
      concurso: 'Concurso',
      departamento: 'Departamento'
    };
    var baseName = fieldNames[field] || field;
    var count = (filterState[field] || []).length;
    btn.textContent = count > 0 ? baseName + ' (' + count + ')' : baseName;

    // Marcar el botón como activo
    var btnEl = dropdown.querySelector('.filtro-btn');
    if (count > 0) btnEl.classList.add('filtro-activo');
    else btnEl.classList.remove('filtro-activo');
  }

  function setupDropdowns() {
    var dropdowns = document.querySelectorAll('.filtro-dropdown');
    if (dropdowns.length === 0) return false;

    dropdowns.forEach(function(dropdown) {
      if (dropdown.dataset.setup === 'true') return;
      dropdown.dataset.setup = 'true';

      buildDropdown(dropdown);

      var btn = dropdown.querySelector('.filtro-btn');
      btn.addEventListener('click', function(e) {
        e.stopPropagation();
        // Cerrar otros dropdowns
        document.querySelectorAll('.filtro-dropdown.abierto').forEach(function(d) {
          if (d !== dropdown) d.classList.remove('abierto');
        });
        dropdown.classList.toggle('abierto');
      });
    });

    // Cerrar al hacer clic fuera
    document.addEventListener('click', function() {
      document.querySelectorAll('.filtro-dropdown.abierto').forEach(function(d) {
        d.classList.remove('abierto');
      });
    });

    // Botón "Limpiar filtros"
    var resetBtn = document.querySelector('.filtro-reset');
    if (resetBtn) {
      resetBtn.addEventListener('click', function() {
        filterState = {};
        document.querySelectorAll('.filtro-dropdown input[type="checkbox"]').forEach(function(cb) {
          cb.checked = false;
        });
        document.querySelectorAll('.filtro-dropdown').forEach(updateButtonLabel);
        applyFilters();
      });
    }

    return true;
  }

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================
  function initAll() {
    var buttons = document.querySelectorAll('.sort-button');
    if (buttons.length === 0) return false;

    buttons.forEach(function(btn) {
      if (btn.dataset.sortAttached === 'true') return;
      btn.dataset.sortAttached = 'true';
      btn.addEventListener('click', function() {
        handleSortClick(btn.dataset.sortTarget, btn);
      });
    });

    setupDropdowns();
    return true;
  }

  if (!initAll()) {
    var tries = 0;
    var interval = setInterval(function() {
      tries++;
      if (initAll() || tries > 30) clearInterval(interval);
    }, 200);
  }
});