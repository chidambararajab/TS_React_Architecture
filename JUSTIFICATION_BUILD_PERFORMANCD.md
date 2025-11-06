# BUILD PERFORMANCE JUSTIFICATION

**File:** `BUILD_PERFORMANCE_JUSTIFICATION.md`  
**Purpose:** explain performance implications of the chosen build choices & runtime libraries, justify them, and list alternatives.  
Format per item: **Purpose | Performance (impact) | Why (chosen)** | **Alternatives**.

---

## Table of contents

1. Bundler & Dev Tooling (Vite / esbuild)
2. Module Format & Tree-shaking (ESM + Rollup)
3. Code-splitting & Lazy-loading (routes / features)
4. Minification / Compression (Terser / esbuild / SW)
5. Source maps & dev/prod parity
6. Dependency choices & runtime cost (React Query, Zustand, Axios, Zod)
7. Asset optimization (images, fonts, CSS)
8. Caching, HTTP/2/3, and CDN
9. Bundle analysis & CI budget
10. Build-time performance (incremental, cached builds)
11. Recommendations / Checklist (what to run in CI)

---

## 1. Bundler & Dev Tooling — **Vite** (uses esbuild in dev, Rollup for build)

- **Purpose:** fast dev server (instant HMR), fast cold-starts; production build via Rollup for optimized bundles.
- **Performance (impact):**
  - Dev: drastically lower cold-start and HMR times compared to Webpack; near-instant edits.
  - Prod build: Rollup yields good tree-shaking and output; build times moderate but acceptable.
- **Why (chosen):**
  - Vite leverages **esbuild** for lightning-fast transforms during development and uses Rollup for production optimizations. This combination gives best DX and solid production output.
- **Alternatives:**
  - **Webpack (with esbuild-loader)** — mature but slower dev HMR; heavier config.
  - **Parcel** — zero-config but less control at scale.
  - **Rome** (emerging) — promising but not yet mainstream for prod builds.

---

## 2. Module Format & Tree-shaking — **ESM + Rollup**

- **Purpose:** use ES modules so tree-shaking can remove unused exports; produce smaller bundles.
- **Performance (impact):**
  - Smaller bundles due to dead-code elimination; better caching because chunk boundaries map to features.
- **Why (chosen):**
  - ESM is native in browsers and works with Vite; Rollup has excellent tree-shaking for ES modules.
- **Alternatives:**
  - CommonJS bundles — worse tree-shaking.
  - Use module federation / micro-frontends — increases complexity.

---

## 3. Code-splitting & Lazy-loading — **Route & Feature-level splits**

- **Purpose:** reduce initial payload by loading only code needed for first render (home, auth) and lazy-load Notes feature.
- **Performance (impact):**
  - Lower Time-to-Interactive (TTI) and First Contentful Paint (FCP).
  - Smaller initial JS download leads to faster parse/execution.
- **Why (chosen):**
  - Feature-based boundaries map to UX flows; lazy `import()` + React `Suspense` keeps entry small and loads features on demand.
- **Alternatives:**
  - Single large bundle — simpler, but bigger initial payload.
  - Preloading critical features on hover (prefetch) to hide latency.

---

## 4. Minification / Compression — **esbuild/Terser + Gzip/Brotli**

- **Purpose:** shrink bundle bytes shipped over the wire (minify + compress).
- **Performance (impact):**
  - Minification reduces size; Brotli on CDN reduces bytes further — major win for slow networks.
- **Why (chosen):**
  - Vite/Rollup provides minification (esbuild or terser plugins). Brotli/Gzip served by CDN or server is standard practice.
- **Alternatives:**
  - Advanced compression (Zopfli) — slower to compress, not necessary in most cases.
  - No compression — unacceptable for production.

---

## 5. Source maps & dev/prod parity

- **Purpose:** developer debugging vs. production size & security tradeoff.
- **Performance (impact):**
  - Source maps increase build size & upload footprint if included in artifacts. Serving them to users is a security/size issue.
- **Why (chosen):**
  - Generate **hidden** or CI-only source maps for error reporting (Sentry) and omit public source maps in production unless needed.
- **Alternatives:**
  - Inline source maps (bad for prod). Omit maps (worse debugging).

---

## 6. Dependency choices & runtime cost

> For each runtime library: Purpose | Performance impact | Why chosen | Alternatives

### a) `react`

- **Purpose:** UI runtime.
- **Performance:** core runtime cost unavoidable; keep React version (18+) for concurrency features and improved scheduling.
- **Why:** modern React 18 features (concurrent rendering, `useTransition`).
- **Alternatives:** Smaller frameworks (Preact) — lower size but different ecosystem.

### b) `@tanstack/react-query` (React Query)

- **Purpose:** server-state caching, background refetch, optimistic updates.
- **Performance (runtime):**
  - Adds moderate JS bytes but reduces re-fetch churn and duplicate network calls (net win).
  - Efficient cache means fewer network roundtrips and faster UI updates.
- **Why:** reduces wasted network and UI thrash; well-optimized internals and deduping.
- **Alternatives:**
  - **SWR** — lighter but less mutation support.
  - **RTK Query** — integrates with Redux but increases bundle if Redux is otherwise unused.

### c) `zustand`

- **Purpose:** tiny store for UI-only state.
- **Performance:**
  - Extremely small (~1–2 KB gzipped). Low runtime overhead.
- **Why:** minimal cost and simple API for shared UI state.
- **Alternatives:** Redux (bigger), Jotai/Recoil (more primitives, slightly larger).

### d) `axios`

- **Purpose:** HTTP client.
- **Performance:**
  - Small overhead vs `fetch`; bundles add a few KB. Cost negligible in large apps.
- **Why:** consistent error handling & interceptors.
- **Alternatives:**
  - Native `fetch` (zero dependency) — smaller bundle. Use a small wrapper to normalize behavior.

### e) `zod`

- **Purpose:** runtime schema validation.
- **Performance:**
  - Validation adds CPU cost at runtime; keep validation at API boundary, not on every render.
- **Why:** safety vs contract drift is worth the small validation cost in most apps.
- **Alternatives:** `io-ts` (heavier), manual checks (error-prone).

---

## 7. Asset optimization (images, fonts, CSS)

- **Purpose:** reduce render-blocking resources and bytes for images/fonts/styles.
- **Performance:**
  - Optimized images (AVIF/WebP) + responsive sizes drastically reduce payload for image-heavy pages.
  - Font subsetting & `font-display: swap` reduce FOIT.
  - Critical CSS inlined reduces FCP.
- **Why:** Network payloads often dominate TTFB → FCP.
- **Alternatives / Tools:**
  - `vite-imagetools` for build-time transforms.
  - Use responsive `<img srcset>` and `picture`.
  - Use CDN image resizing (Cloudinary, imgix) for server-side optimization.

---

## 8. Caching, HTTP/2/3, and CDN

- **Purpose:** deliver assets quickly and cache aggressively client-side & CDN.
- **Performance:**
  - Long cache TTLs for hashed assets reduce repeated downloads.
  - HTTP/2 multiplexing reduces connection setup overhead; HTTP/3 improves latency.
- **Why:** network latency is often the largest factor for global users.
- **Alternatives:**
  - Single server without CDN — acceptable for internal apps but not for global scale.
  - Use Service Workers for offline caching (careful with updates).

---

## 9. Bundle analysis & CI budget

- **Purpose:** keep bundle size under control and detect regressions.
- **Performance:**
  - Smaller bundles → smaller parse/compile time in browser → faster interactivity.
- **Why:** integrate bundle analysis (rollup visualizer, vite-plugin-visualizer) in CI to fail PRs if bundle grows beyond threshold.
- **Alternatives / Tools:**
  - `source-map-explorer`, `webpack-bundle-analyzer`.

---

## 10. Build-time performance (incremental & caching)

- **Purpose:** speed up CI & dev builds using caching and incremental compilation.
- **Performance:**
  - Caching node_modules, Vite cache, and artifact caching reduces CI wall time.
- **Why:** faster CI feedback improves developer productivity.
- **Alternatives / Tools:**
  - Remote cache (Nx, Turborepo, esbuild cache) for monorepos.
  - Use esbuild for full builds in very large projects (faster than Rollup but fewer optimizations).

---

## 11. Recommendations & Checklist (practical actions to improve build perf)

**Build / CI**

- Use Vite production build (`vite build`) with Rollup optimizations enabled.
- Enable `build.sourcemap = false` for public production builds; generate hidden/CI maps for error reporting.
- Integrate `vite-plugin-visualizer` or `rollup-plugin-visualizer` and fail CI on > X KB regression.
- Cache node modules and Vite cache in CI.

**Runtime**

- Serve assets with Brotli on CDN; fallback to Gzip.
- Use long cache TTLs for hashed assets and short TTL for HTML.
- Implement HTTP/2 or HTTP/3 on the CDN / origin.

**Code**

- Tree-shake dead code by using ESM imports and avoiding large wildcard imports.
- Replace heavy libs with lighter alternatives if they are only used for small features (e.g., `fetch` vs `axios`).
- Move non-critical components behind `Suspense` + lazy imports.

**UX**

- Use skeleton UIs and `keepPreviousData` to minimize perceived load.
- Virtualize large lists (`react-virtual`, `tanstack-virtual`).
- Use `useTransition` for non-blocking UI updates.

**Testing & Monitoring**

- Add Lighthouse and bundle size checks in PR pipelines.
- Monitor real-user metrics (RUM): FCP, LCP, TTI, TBT and bundle parse/compile times.

---

## Quick comparison table (why chosen vs common alternatives)

| Concern            |             Chosen | Why chosen                        | Alternative                   |
| ------------------ | -----------------: | --------------------------------- | ----------------------------- |
| Dev speed          | **Vite (esbuild)** | Instant dev HMR                   | Webpack (slower)              |
| Server-state       |    **React Query** | Built-in mutations/caching        | SWR (lighter, fewer features) |
| Client UI state    |        **Zustand** | Tiny & fast                       | Redux (larger)                |
| HTTP client        |          **axios** | interceptor & error normalization | `fetch` (zero deps)           |
| Runtime validation |            **zod** | ergonomic, fast                   | io-ts (heavier)               |
| Image transforms   |        CDN / build | Serve optimized formats           | Serve raw assets              |

---

## Final words (senior summary)

- **Primary goal:** minimize time-to-interactive and perceived latency while keeping developer feedback loops fast.
- **Tactics chosen:** fast dev server (Vite), ESM + Rollup build for effective tree-shaking, code-splitting at feature/route level, Brotli/Gzip compression, CDN + long-caching for hashed assets, and runtime libs (React Query + Zustand) chosen because they **reduce extraneous network and JS churn** (React Query) and **impose almost zero runtime cost** for client state (Zustand).
- **Measure everything:** use CI checks (bundle analyzer, Lighthouse), and RUM in production to validate improvements.

If you want, I can:

- produce a small CI workflow (GitHub Actions) that runs bundle-analyzer and Lighthouse and fails PRs on regressions, or
- generate a short `performance-checklist.md` that developers can follow during PR review.
