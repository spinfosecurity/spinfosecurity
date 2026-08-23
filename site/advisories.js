(() => {
  const list = document.getElementById("adv-list");
  const empty = document.getElementById("adv-empty");
  const resultCount = document.getElementById("result-count");
  const query = document.getElementById("adv-query");
  if (!list || !query) return;

  const rows = Array.from(list.querySelectorAll(".adv-row"));
  let severity = "ALL";
  let kind = "ALL";

  const setPressed = (attr, value) => {
    document.querySelectorAll(`[${attr}]`).forEach((btn) => {
      const active = btn.getAttribute(attr) === value;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-pressed", active ? "true" : "false");
    });
  };

  const apply = () => {
    const q = (query.value || "").trim().toLowerCase();
    let visible = 0;
    for (const row of rows) {
      const sevOk = severity === "ALL" || row.dataset.severity === severity;
      const kindOk = kind === "ALL" || row.dataset.kind === kind;
      const searchOk = !q || (row.dataset.search || "").includes(q);
      const show = sevOk && kindOk && searchOk;
      row.classList.toggle("is-hidden", !show);
      if (show) visible += 1;
    }
    if (empty) empty.hidden = visible !== 0;
    if (resultCount) {
      resultCount.textContent =
        visible === rows.length
          ? `Showing ${visible} advisories. Open any row for the official CISA write-up.`
          : `Showing ${visible} of ${rows.length} advisories.`;
    }
  };

  document.querySelectorAll("[data-filter-severity]").forEach((btn) => {
    btn.addEventListener("click", () => {
      severity = btn.getAttribute("data-filter-severity") || "ALL";
      setPressed("data-filter-severity", severity);
      apply();
    });
  });

  document.querySelectorAll("[data-filter-kind]").forEach((btn) => {
    btn.addEventListener("click", () => {
      kind = btn.getAttribute("data-filter-kind") || "ALL";
      setPressed("data-filter-kind", kind);
      apply();
    });
  });

  let timer = 0;
  query.addEventListener("input", () => {
    window.clearTimeout(timer);
    timer = window.setTimeout(apply, 80);
  });
})();
