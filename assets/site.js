// Copy buttons: homepage commands and every code block in rendered guides.
function copyText(btn, text) {
  navigator.clipboard.writeText(text).then(function () {
    var old = btn.textContent; btn.textContent = 'Copied';
    setTimeout(function () { btn.textContent = old; }, 1200);
  });
}
document.querySelectorAll('button[data-cmd]').forEach(function (b) {
  b.addEventListener('click', function () { copyText(b, b.getAttribute('data-cmd')); });
});
document.querySelectorAll('main.doc pre').forEach(function (pre) {
  var b = document.createElement('button');
  b.className = 'copy'; b.type = 'button'; b.textContent = 'Copy';
  b.addEventListener('click', function () { copyText(b, pre.innerText.replace(/Copy$/, '').trim()); });
  pre.appendChild(b);
});

// Homepage filter: text search + platform chips.
var q = document.getElementById('q');
if (q) {
  var plat = 'all';
  var cards = Array.prototype.slice.call(document.querySelectorAll('.card'));
  function apply() {
    var t = q.value.trim().toLowerCase();
    cards.forEach(function (c) {
      var ok = (plat === 'all' || c.dataset.plat === plat) && (!t || c.dataset.text.indexOf(t) !== -1);
      c.style.display = ok ? '' : 'none';
    });
    document.querySelectorAll('[data-group]').forEach(function (g) {
      var any = g.querySelector('.card:not([style*="none"])');
      g.style.display = any ? '' : 'none';
    });
    var none = document.getElementById('none');
    if (none) none.style.display = cards.some(function (c) { return c.style.display !== 'none'; }) ? 'none' : '';
  }
  q.addEventListener('input', apply);
  document.querySelectorAll('.chips button').forEach(function (b) {
    b.addEventListener('click', function () {
      document.querySelectorAll('.chips button').forEach(function (x) { x.classList.remove('on'); });
      b.classList.add('on'); plat = b.dataset.plat; apply();
    });
  });
}
