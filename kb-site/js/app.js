const storageKeys = {
    theme: "docs-theme",
};

const docSearchIndex = window.DOC_SEARCH_INDEX ?? [];

const docContent = document.getElementById("doc-content");
const tocRoot = document.getElementById("toc-links");
const searchInput = document.getElementById("search-input");
const searchResults = document.getElementById("search-results");
const searchClear = document.getElementById("search-clear");
const themeToggle = document.getElementById("theme-toggle");

function setTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem(storageKeys.theme, theme);
    themeToggle.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
    themeToggle.querySelector("span:last-child").textContent = theme === "dark" ? "Light mode" : "Dark mode";
}

function initTheme() {
    const storedTheme = localStorage.getItem(storageKeys.theme);
    const preferredTheme = storedTheme || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    setTheme(preferredTheme);
}

function renderToc() {
    const headings = [...docContent.querySelectorAll("h2, h3")];
    tocRoot.innerHTML = headings
        .map((heading) => `<a class="toc-link" href="#${heading.id}">${heading.textContent}</a>`)
        .join("");
}

function openSearchResults(items) {
    if (!items.length) {
        searchResults.innerHTML = `<div class="search-results-card"><div class="search-result-item">No results</div></div>`;
    } else {
        searchResults.innerHTML = `<div class="search-results-card">${items
            .map((item) => `<a class="search-result-item" href="${item.url}"><strong>${item.title}</strong><br><small>${item.summary}</small></a>`)
            .join("")}</div>`;
    }

    searchResults.classList.add("is-active");
}

function closeSearchResults() {
    searchResults.classList.remove("is-active");
}

function setupSearch() {
    const fuse = window.Fuse ? new Fuse(docSearchIndex, {
        keys: ["title", "summary"],
        threshold: 0.35,
        ignoreLocation: true,
    }) : null;

    const runSearch = () => {
        const query = searchInput.value.trim();
        if (!query) {
            closeSearchResults();
            return;
        }

        const matches = fuse ? fuse.search(query).map((result) => result.item) : docSearchIndex.filter((item) => {
            const haystack = `${item.title} ${item.summary}`.toLowerCase();
            return haystack.includes(query.toLowerCase());
        });

        openSearchResults(matches.slice(0, 8));
    };

    searchInput.addEventListener("input", runSearch);
    searchInput.addEventListener("focus", runSearch);
    searchClear.addEventListener("click", () => {
        searchInput.value = "";
        searchInput.focus();
        closeSearchResults();
    });

    document.addEventListener("click", (event) => {
        if (!event.target.closest(".search-wrap")) {
            closeSearchResults();
        }
    });
}

function setupNavbar() {
    document.querySelectorAll(".navbar-burger").forEach((burger) => {
        burger.addEventListener("click", () => {
            const targetId = burger.dataset.target;
            const target = document.getElementById(targetId);
            burger.classList.toggle("is-active");
            target.classList.toggle("is-active");
        });
    });
}

function setupPanels() {
    document.querySelectorAll("[data-panel-toggle]").forEach((button) => {
        button.addEventListener("click", () => {
            const panel = document.getElementById(button.dataset.panelToggle);
            const hidden = panel.getAttribute("data-panel-hidden") === "true";
            panel.setAttribute("data-panel-hidden", hidden ? "false" : "true");
        });
    });
}

function setupTocObserver() {
    const links = [...tocRoot.querySelectorAll(".toc-link")];
    const headings = links
        .map((link) => document.getElementById(link.getAttribute("href").slice(1)))
        .filter(Boolean);

    if (!headings.length) {
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (!entry.isIntersecting) {
                return;
            }

            links.forEach((link) => link.classList.remove("is-active"));
            const activeLink = links.find((link) => link.getAttribute("href") === `#${entry.target.id}`);
            if (activeLink) {
                activeLink.classList.add("is-active");
            }
        });
    }, {
        rootMargin: "-35% 0px -55% 0px",
        threshold: 0.1,
    });

    headings.forEach((heading) => observer.observe(heading));
}

themeToggle.addEventListener("click", () => {
    const currentTheme = document.documentElement.getAttribute("data-theme");
    setTheme(currentTheme === "dark" ? "light" : "dark");
});

initTheme();
renderToc();
setupSearch();
setupNavbar();
setupPanels();
setupTocObserver();