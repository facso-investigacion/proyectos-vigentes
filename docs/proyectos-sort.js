// proyectos-sort.js
// Sort manual del DOM, independiente de List.js / Quarto

document.addEventListener('DOMContentLoaded', function() {

  // Estado: dirección actual del orden por campo
  var sortState = { target: null, dir: null };

  // Función para extraer el valor de un campo desde una tarjeta
  function getFieldValue(card, target) {
    // Los campos están en spans con clase "listing-<campo>"
    var selector = '.listing-' + target;
    var el = card.querySelector(selector);
    if (!el) return '';
    return el.textContent.trim().toLowerCase();
  }

  // Reordenar las tarjetas dentro del grid
  function sortCards(target, dir) {
    var grid = document.querySelector('.proyectos-grid');
    if (!grid) return;

    var cards = Array.from(grid.querySelectorAll('.proyecto-card'));
    if (cards.length === 0) return;

    cards.sort(function(a, b) {
      var va = getFieldValue(a, target);
      var vb = getFieldValue(b, target);

      // Si parece numérico (años), comparar como número
      var na = parseFloat(va);
      var nb = parseFloat(vb);
      if (!isNaN(na) && !isNaN(nb)) {
        return dir === 'asc' ? na - nb : nb - na;
      }

      // Comparación de texto
      if (va < vb) return dir === 'asc' ? -1 : 1;
      if (va > vb) return dir === 'asc' ?  1 : -1;
      return 0;
    });

    // Reinsertar en el nuevo orden
    cards.forEach(function(card) {
      grid.appendChild(card);
    });
  }

  function handleSortClick(target, btn) {
    // Alternar dirección
    var newDir;
    if (sortState.target === target) {
      newDir = sortState.dir === 'desc' ? 'asc' : 'desc';
    } else {
      newDir = 'desc';
    }
    sortState = { target: target, dir: newDir };

    sortCards(target, newDir);

    // Indicadores visuales
    document.querySelectorAll('.sort-button').forEach(function(b) {
      var ind = b.querySelector('.sort-indicator');
      if (ind) ind.textContent = '';
    });
    var ind = btn.querySelector('.sort-indicator');
    if (ind) ind.textContent = newDir === 'asc' ? ' ▲' : ' ▼';
  }

  // Reaplica el orden actual (útil tras filtros que reordenan el DOM)
  function reapplyCurrentSort() {
    if (sortState.target) sortCards(sortState.target, sortState.dir);
  }

  function attachSortHandlers() {
    var buttons = document.querySelectorAll('.sort-button');
    if (buttons.length === 0) return false;

    buttons.forEach(function(btn) {
      if (btn.dataset.sortAttached === 'true') return;
      btn.dataset.sortAttached = 'true';
      btn.addEventListener('click', function() {
        handleSortClick(btn.dataset.sortTarget, btn);
      });
    });

    // Observar cambios en el grid para reaplicar el orden tras filtros
    var grid = document.querySelector('.proyectos-grid');
    if (grid && !grid.dataset.sortObserved) {
      grid.dataset.sortObserved = 'true';
      var observer = new MutationObserver(function() {
        // Solo reaplicar si hay sort activo y el cambio no fue nuestro
        if (!sortState.target) return;
        if (grid.dataset.sortInProgress === 'true') return;

        grid.dataset.sortInProgress = 'true';
        reapplyCurrentSort();
        setTimeout(function() { grid.dataset.sortInProgress = 'false'; }, 50);
      });
      observer.observe(grid, { childList: true });
    }

    return true;
  }

  if (!attachSortHandlers()) {
    var tries = 0;
    var interval = setInterval(function() {
      tries++;
      if (attachSortHandlers() || tries > 30) clearInterval(interval);
    }, 200);
  }
});