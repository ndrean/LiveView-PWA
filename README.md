# Offline first Phoenix LiveView PWA

An example of a real-time, collaborative multi-page web app built with `Phoenix LiveView` designed for offline-first ready; it is packaged as a [PWA](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps).

While the app supports full offline interaction and local persistence using CRDTs (via `Yjs` and `y-indexeddb`), the core architecture is still grounded in a server-side source of truth. The server database ultimately reconciles all updates, ensuring consistency across clients.

This design enables:

✅ Full offline functionality and interactivity

✅ Real-time collaboration between multiple users

✅ Reconciliation with a central, trusted source of truth when back online

> A page won't be cached if it is not visited. This is because we don't want ot preload pages as it will capture an uotdated CSRF token.

## Architecture at a glance

- Client-side CRDTs (`Yjs`) manage local state changes (e.g. counter updates), even when offline
- Server-side database (`Postgres` or `SQLite`) remains authoritative
- When the client reconnects, local CRDT updates are synced with the server:

  - In one page, via `Postgres` and `Phoenix.Sync` wit logical replication
  - In another, via `SQLite` using a `Phoenix.Channel` message

- Offline first solutions naturally offloads the reactive UI logic to JavaScript. We used `SolidJS`.
- It uses `Vite` as the bundler. The `vite-plugin-pwa` registers a Service Worker to cache app shell and assets for offline usage.

## How it works

### Optimistic Updates with Centralized Reconciliation

Although we leverage Yjs (a CRDT library) under the hood, this isn’t a fully peer-to-peer, decentralized CRDT system. Instead, in this demo we have:

- No direct client-to-client replication (not pure lazy/optimistic replication).
- No concurrent writes against the same replica—all operations are serialized through the server.
- A _centralized authoritative server_.

Writes are _serialized_ but actions are concurrent. What we do have is _asynchronous reconciliation_ with an [operation-based CRDT](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type#Counters) approach:

- User actions (e.g. clicking “decrement” on the counter) are applied locally to a `Yjs` document stored in `IndexedDB`.
- The same operation (not the full value) is sent to the server via `Phoenix` (either `Phoenix.Sync` or a `Phoenix.Channel`).
- `Phoenix` broadcasts that op to all connected clients.
- Upon receipt, each client applies the op to its local `Yjs` document—order doesn’t matter, making it commutative.
- The server database (`Postgres` or `SQLite`) remains the single source of truth and persists ops in sequence.

> In CRDT terms: We use an operation-based CRDT (CRDT Counter) for each shared value Ops commute (order-independent) even though they pass through a central broker.

### Rendering Strategy: SSR vs. Client-Side Hooks

To keep the UI interactive both online and offline, we mix `LiveView`’s server-side rendering (SSR) with a client-side reactive framework. We used `SolidJS` because it's lightweight, no virtual DOM, and has simple a simple primitives  (`render`, `createSignal`) when we want to inject such a component into the DOM.

- Online (`LiveView` SSR or JS-hooks):

  - The PhxSync page renders a LiveView using `streams` and the "click" event sends data to the client to update the local `Yjs` document.
  - The YjsCh page renders a JS-hook which initialises a `SolidJS` component. In the JS-hook, the `SolidJS` communicates via a Channel to update the database and the local `Yjs` document.

- Offline (Manual Rendering)
  - We detect the status switch via a server polling.
  - We retrive the HTML document from the `Cache API`.
  - We update the current DOM with the cached HTML and inject the correct JS component.
  - The component reads from and writes to the local `Yjs`+`IndexedDB` replica and remains fully interactive.

### Service Worker & Asset Caching

`vite-plugin-pwa` generates a Service Worker that:

- Pre-caches the app shell (HTML, CSS, JS) on install.
- Intercepts navigations to serve the cached app shell for offline-first startup.

This ensures the entire app loads reliably even without network connectivity.

## Results

Deployed on `Fly.io`: <https://liveview-pwa.fly.dev/>

The standalone PWA is 2.1 MB (page weigth).

## Table of Contents

- [Offline first Phoenix LiveView PWA](#offline-first-phoenix-liveview-pwa)
  - [Architecture at a glance](#architecture-at-a-glance)
  - [How it works](#how-it-works)
    - [Optimistic Updates with Centralized Reconciliation](#optimistic-updates-with-centralized-reconciliation)
    - [Rendering Strategy: SSR vs. Client-Side Hooks](#rendering-strategy-ssr-vs-client-side-hooks)
    - [Service Worker \& Asset Caching](#service-worker--asset-caching)
  - [Results](#results)
  - [Table of Contents](#table-of-contents)
  - [What?](#what)
  - [Why?](#why)
  - [Design goals](#design-goals)
  - [Common pitfall of combining LiveView with CSR components](#common-pitfall-of-combining-liveview-with-csr-components)
  - [Tech overview](#tech-overview)
    - [Implementation highlights](#implementation-highlights)
  - [About the Yjs-Stock page](#about-the-yjs-stock-page)
  - [About PWA](#about-pwa)
    - [Updates life-cycle](#updates-life-cycle)
  - [Usage](#usage)
  - [Details of Pages](#details-of-pages)
    - [Yjs-Ch and PhxSync stock "manager"](#yjs-ch-and-phxsync-stock-manager)
    - [Pg-Sync-Stock](#pg-sync-stock)
    - [FlightMap](#flightmap)
  - [Login](#login)
  - [Navigation](#navigation)
  - [Vite](#vite)
    - [Package.json and `pnpm` workspace (nor not)](#packagejson-and-pnpm-workspace-nor-not)
    - [Phoenix live\_reload](#phoenix-live_reload)
    - [HMR in DEV mode](#hmr-in-dev-mode)
    - ["env" config](#env-config)
    - [Root layout in :dev/:prod setup](#root-layout-in-devprod-setup)
    - [Tailwind v4](#tailwind-v4)
    - [Resolve assets with Vite config](#resolve-assets-with-vite-config)
    - [Optmise CSS with `lightningCSS` in prod mode](#optmise-css-with-lightningcss-in-prod-mode)
    - [Client Env](#client-env)
    - [Static assets](#static-assets)
      - [`Vite.ex` module](#viteex-module)
      - [Static copy](#static-copy)
      - [DEV mode](#dev-mode)
      - [PROD mode](#prod-mode)
    - [Performance optimisation: Dynamic CSS loading](#performance-optimisation-dynamic-css-loading)
    - [VitePWA plugin and Workbox Caching Strategies](#vitepwa-plugin-and-workbox-caching-strategies)
  - [Yjs](#yjs)
  - [Misc](#misc)
    - [Presence through Live-navigation](#presence-through-live-navigation)
    - [Manifest](#manifest)
    - [Page Caching](#page-caching)
  - [Publish](#publish)
  - [Postgres setup to use Phoenix.Sync](#postgres-setup-to-use-phoenixsync)
  - [Fly volumes](#fly-volumes)
  - [Documentation source](#documentation-source)
  - [Resources](#resources)
  - [License](#license)
  - [Enhance](#enhance)

## What?

**Context**: we want to experiment PWA collaborative webapps using Phoenix LiveView.

What are we building? A three pages webap:

1. We mimic a stock manager in two versions. Every user can pick from the stock which is broadcasted and synced to the databased. The picked amounts are cumulated when offline and the database is synced and state reconciliation.
   - PgSync-Stock page features `phoenix_sync` in _embedded_ mode streaming logical replicates of a Postgres table.
   - Yjs-Channel page features 'Sqlite` used as a backup via a Channel.
2. FlightMap. This page proposes an interactive map with a form with two inputs where **two** users can edit collaboratively a form to display markers on the map and then draw a great circle between the two points.

## Why?

Traditional Phoenix LiveView applications face several challenges in offline scenarios:

LiveView's WebSocket architecture isn't naturally suited for PWAs, as it requires constant connection for functionality.

It is challenging to maintain consistent state across network interruptions between the client and the server.

Since we need to setup a Service Worker to cache HTML pages and static assets to work offline, we need a different bundler from the one used by default with `LiveView`.

## Design goals

- **collaborative** (online): Clients sync via _pubsub updates_ when connected, ensuring real-time consistency.
- **optimistic UI**: The function "click on stock" assumes success and will reconciliate later.
- **database**:
  - We use `SQLite` as the "canonical" source of truth for the Yjs-Stock counter.
  - `Postgres` is used for the `Phoenix_sync` process for the PgSync-Stock counter.
- **Offline-First**: The app remains functional offline (through the `Cache` API and reactive JS components), with clients converging to the correct state on reconnection.
- **PWA**: Full PWA features, meaning it can be _installed_ as a standalone app and can be _updated_. A `Service Worker` runs in a separate thread and caches the assets. It is setup with `VitePWA`.

## Common pitfall of combining LiveView with CSR components

The client-side rendered components are - when online - mounted via hooks under the tag `phx-update="ignore"`.

These components have they own lifecycle. They can leak or stack duplicate components if you don't cleanup them properly.
The same applies to "subscriptions/observers" primitives from (any) the state manager. You must _unsubscribe_, otherwise you might get multiples calls and weird behaviours.

⭐️ LiveView hooks comes with a handy lifecyle and the `destroyed` callback is essential.

`SolidJS` makes this easy as it can return a `cleanupSolid` callback (where you take a reference to the SolidJS component in the hook).
You also need to clean _subscriptions_ (when using a store manager).

The same applies when you navigate offline; you have to run cleanup functions, both on the components and on the subsriptions/observers from the state manager.

## Tech overview

| Component                  | Role                                                                                                              |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Vite                       | Build and bundling framework                                                                                      |
| SQLite                     | Embedded persistent storage of latest Yjs document                                                                |
| Postgres                   | Supports logical replication                                                                                      |
| Phoenix LiveView           | UI rendering, incuding hooks                                                                                      |
| Phoenix.Sync               | Relays Postgres streams into LiveView                                                                             |
| PubSub / Phoenix.Channel   | Broadcast/notifies other clients of updates / conveys CRDTs binaries on a separate websocket (from te LiveSocket) |
| Yjs / Y.Map                | Holds the CRDT state client-side (shared)                                                                         |
| y-indexeddb                | Persists state locally for offline mode                                                                           |
| Valtio                     | Holds local ephemeral state                                                                                       |
| Hooks                      | Injects communication primitives and controls JavaScript code                                                     |
| Service Worker / Cache API | Enable offline UI rendering and navigation by caching HTML pages and static assets                                |
| SolidJS                    | renders reactive UI using signals, driven by Yjs observers                                                        |
| Leaflet                    | Map rendering                                                                                                     |
| MapTiler                   | enable vector tiles                                                                                               |
| WebAssembly container      |  high-performance calculations for map "great-circle" routes use `Zig` code compiled to `WASM`                    |

### Implementation highlights

We use different approaches based on the page requirements:

1. Yjs-Channel: the counter is a reactive component rendered via a hook by `SolidJS`. When offline, we render the component directly.
2. PhxSync: the counter is rendered by LiveView and receives `Psotgres` streams. When offline, we render the exact same component directly.
3. The source of truth is the database. Every client has a local replica (`IndexedDB`) which handles offline changes and gets updates when online.
4. FlightMap. Local state management (`Valtio`) for the collaborative Flight Map page without server-side persistence of the state nor client-side.

- **Build tool**:
  We use Vite as the build tool to bundle and optimize the application and enable PWA features seamlessly.
  The Service Worker to cache HTML pages and static assets.

- **reactive JS components**:
  Every reactive component works in the following way. Local changes fomr within the component mutate YDoc and an `yjs`-listener will update the component state to render. Any received remote change mutates the `YDoc`, thus triggers the component rendering.

- **FlightMap page**:
  We use a local state manager (`Valtio` using proxies).
  The inputs (selected airports) are saved to a local state.
  Local UI changes mutate the state and are sent to the server. The server broadcasts the data.
  We have state observers which update the UI if the origin is not remote.

- **Component Rendering Strategy**:
  - online: use LiveView hooks
  - offline: hydrate the HTML with cached documents and run reactive JavaScript components

## About the Yjs-Stock page

  ```mermaid
  ---
  title: "SQLite & Channel & YDoc Implementation"
  ---
  flowchart
      YDoc(YDoc <br>IndexedDB)
      Channel[Phoenix Channel]
      SQLite[(SQLite DB)]
      Client[Client]

      Client -->|Local update| YDoc
      YDoc -->|Send ops| Channel
      Channel -->|Update counter| SQLite
      SQLite -->|Return new value| Channel
      Channel -->|Broadcast| Client
      Client -->|Remote Update| YDoc

      YDoc -.->|Reconnect <br> send stored ops| Channel


  style YDoc fill:#e1f5fe
  style Channel fill:#fff3e0
  ```

<br/>

```mermaid
---
title: "Postgres & Phoenix_Sync & YDoc Implementation"
---
flowchart
    YDoc[YDoc <br> IndexedDB]
    PG[(Postgres DB)]
    PhoenixSync[Phoenix_Sync<br/>Logical Replication]
    Client[Client]

    Client -->|update local| YDoc
    YDoc -->|Send ops| PG
    PG -->|Logical replication| PhoenixSync
    PhoenixSync -->|Stream changes| Client
    Client -->|Remote Update| YDoc

    YDoc -.->|Reconnect <br> send stored ops| PG

style YDoc fill:#e1f5fe
style PhoenixSync fill:#fff3e0
style PG fill:#f3e5f5

```

## About PWA

A Progressive Web App (PWA) is a type of web application that provides an app-like experience directly in the browser.

It has:

- offline support
- is "installable":

<img width="135" alt="Screenshot 2025-05-08 at 22 02 40" src="https://github.com/user-attachments/assets/dddaaac7-9255-419b-a5ad-44a2a891e93a" />
<br/>

The core components are setup using `Vite` in the _vite.config.js_ file.

- **Service Worker**:
  A background script - separate thread - that acts as a proxy: intercepts network requests and enables offline caching and background sync.
  We use the `VitePWA` plugin to enable the Service Worker life-cycle (manage updates)

- Web App **Manifest** (manifest.webmanifest)
  A JSON file that defines the app’s name, icons, theme color, start URL, etc., used to install the webapp.
  We produce the Manifest with `Vite` via in the "vite.

- HTTPS (or localhost):
  Required for secure context: it enables Service Workers and trust.

`Vite` builds the SW for us via the `VitePWA` plugin by declarations in "vite.config.js". Check [Vite](#vite)

The SW is started by the main script, early, and must preload all the build static assets as the main file starts before the SW runtime caching is active.

Since we want offline navigation, we precache the rendered HTML as well.

### Updates life-cycle

A Service Worker (SW) runs in a _separate thread_ from the main JS and has a unique lifecycle made of 3 key phases: install / activate / fetch

In action:

1. Make a change in the client code, git push/fly deploy:
   -> a button appears and the dev console shows a push and waiting stage:

<img width="1413" alt="Screenshot 2025-05-08 at 09 40 28" src="https://github.com/user-attachments/assets/a4086fe3-4952-48de-818c-b12fe1819823" />
<br/>

2. Click the "refresh needed"
   -> the Service Worker and client claims are updated seamlessly, and the button is in the hidden "normal" state.

<img width="1414" alt="Screenshot 2025-05-08 at 09 41 55" src="https://github.com/user-attachments/assets/7687fd61-f5b8-4298-ab96-144cdb297e6e" />
</br>

Service Workers don't automatically update unless:

- The sw.js file has changed (based on byte comparison).

- The browser checks periodically (usually every 24 hours).

- When a new SW is detected:

  - New SW enters installing state.

  - It waits until no existing clients are using the old SW.

  - Then it activates.

```mermaid
sequenceDiagram
  participant User
  participant Browser
  participant App
  participant OldSW as Old Service Worker
  participant NewSW as New Service Worker

  Browser->>OldSW: Control App
  App->>Browser: registerSW()

  App->>App: code changes
  Browser->>NewSW: Downloads New SW
  NewSW->>Browser: waiting phase
  NewSW-->>App: message: onNeedRefresh()
  App->>User: Show <button> onNeedRefresh()
  User->>App: Clicks Update Button
  App->>NewSW: skipWaiting()
  NewSW->>Browser: Activates
  NewSW->>App: Takes control (via clients.claim())
```

## Usage

```elixir
# mix.exs
{:exqlite, "0.30.1"},
{:req, "~> 0.5.8"},
{:nimble_csv, "~> 1.2"},
{:postgrex, "~> 0.20.0"},
{:electric, "~> 1.0.13"},
{:phoenix_sync, "~> 0.4.3"},
```

Client package are setup with `pnpm`: check [▶️ package.json](https://github.com/dwyl/PWA-Liveview/blob/main/assets/package.json)

1/ **dev** setup with _IEX_ session

```sh
# install all dependencies including Vite
mix deps.get
mix ecto.create && mix ecto.migrate
pnpm install --prefix assets
# start Phoenix server, it will also compile the JS
iex -S mix phx.server
```

2/ Run a local Docker container in **mode=prod**

Firstly setup Postgres in _logical replication_ mode.

```yml
services:
  pg:
    image: postgres:17
    container_name: pg17
    environment:
      # PostgreSQL environment variables are in the form POSTGRES_*
      POSTGRES_PASSWORD: 1234
      POSTGRES_USER: postgres
      POSTGRES_DB: elec_prod
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"] # <- !! admin user is "postgres"
      interval: 5s
      timeout: 5s
      retries: 10
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5000:5432"

    command: # <- set variables via a command
      - -c
      - listen_addresses=*
      - -c
      - wal_level=logical
      - -c
      - max_wal_senders=10
```

<br/>

This also opens the port 5000 for inspection via the `psql` client.

In another terminal, you can do:

```sh
> PGPASSWORD=1234 psql -h localhost -U postgres -d elec_prod -p 5000

# psql (17.5 (Postgres.app))
# Type "help" for help.

elec_prod=#
```

and paste the command to check:

```sh
elec_prod=# select name, setting from pg_settings where name in ('wal_level','max_worker_processes','max_replication_slots','max_wal_senders','shared_preload_libraries');
           name           | setting
--------------------------+---------
 max_replication_slots    | 10
 max_wal_senders          | 10
 max_worker_processes     | 8
 shared_preload_libraries |
 wal_level                | logical
(5 rows)
```

You can run safely (meaning the migrations will run or not, and complete):

[▶️ Dockerfile](https://github.com/dwyl/PWA-Liveview/blob/main/Dockerfile)

[▶️ docker-compose.yml](https://github.com/dwyl/PWA-Liveview/blob/main/docker-compose.yml)

```sh
docker compose up --build
```

> You can take a look at the build artifacts by running into another terminal

```sh
> docker compose exec -it web cat  lib/solidyjs-0.1.0/priv/static/.vite/manifest.json
```

## Details of Pages

### Yjs-Ch and PhxSync stock "manager"

You click on a counter and it goes down..! The counter is broacasted and handled by a CRDT backed into a SQLite table.
A user can click offline, and on reconnection, all clients will get updated with the lowest value (business rule).

<img width="1404" alt="Screenshot 2025-05-08 at 22 05 15" src="https://github.com/user-attachments/assets/ba8373b5-defc-40f9-b497-d0086eb10ccc" />
<br/>

### Pg-Sync-Stock

Available at "/elec"

### FlightMap

Available at `/map`.

> ! It uses a free tier of Maptiler, so might not available!

It displays an _interactive_ and _collaborative_ (two-user input) route planning with vector tiles.
The UI displays a form with two inputs, which are pushed to Phoenix and broadcasted via Phoenix PubSub. A marker is drawn by `Leaflet` to display the choosen airport on a vector-tiled map using `MapTiler`.

<img width="1398" alt="Screenshot 2025-05-08 at 22 06 29" src="https://github.com/user-attachments/assets/1c5a82b2-8302-44a4-93dd-87ac215105e3" />
<br/>

Key features:

- collaborative input
- `Valtio`-based _local_ (browser only) ephemeral state management (no complex conflict resolution needed)
- WebAssembly-powered great circle calculations: CPU-intensive calculations works offline
- Efficient map rendering with MapTiler and _vector tiles_ with smaller cache size (vector data vs. raster image files)

> [**Great circle computation**] It uses a WASM module. `Zig` is used to compute a "great circle" between two points, as a list of `[lat, long]` spaced by 100km. The `Zig` code is compiled to WASM and available for the client JavaScript to run it. Once the list of successive coordinates are in JavaScript, `Leaflet` can use it to produce a polyline and draw it into a canvas. We added a WASM module to implement great circle route calculation as a showcase of WASM integration. A JAvascript alternative would be to use [turf.js](https://turfjs.org/docs/api/greatCircle).
> check the folder "/zig-wasm"

> [**Airport dataset**] We use a dataset from <https://ourairports.com/>. We stream download a CSV file, parse it (`NimbleCSV`) and bulk insert into an SQLite table. When a user mounts, we read from the database and pass the data asynchronously to the client via the liveSocket on the first mount. We persist the data in `localStorage` for client-side search. The socket "airports" assign is then pruned to free the server's socket.

▶️ [Airports](<(https://github.com/dwyl/PWA-Liveview/blob/main/lib/LiveviewPwa/db/Airports.ex)>), [LiveMap](https://github.com/dwyl/PWA-Liveview/blob/main/lib/LiveviewPwaweb/live/live_map.ex)

> The Websocket is configured with `compress: true` (cf <https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration>) to enable compression of the 1.1MB airport dataset through the LiveSocket.

Below a diagram showing the flow between the database, the server and the client.

```mermaid
sequenceDiagram
    participant Client
    participant LiveView
    participant Database

    Client->>LiveView: mount (connected)
    Client->>Client: check localStorage/Valtio
    alt cached data exists and valid
        Client->>LiveView: "cache-checked" (cached: true)
        LiveView->>Client: verify hash
    else no valid cache
        Client->>LiveView: "cache-checked" (cached: false)
        LiveView->>Database: fetch_airports()
        Database-->>LiveView: airports data
        LiveView->>Client: "airports" event with data
        Client->>Client: update localStorage + Valtio
    end
```

## Login

The flow is:

- Live login page => POST controller => redirect to a logged-in LiveView => authorized to "live_navigate"

It displays a dummy login, just to assign a (auto-incremented) user_id and an "access\_\_token".

The _access token_ is passed into the session, thus avialable in the LiveView.

We use the _csrsf token_ to build the custom "userSocket".
With this, you get the session via the `connect_info` in the `connect/3` of "UserSocket".
You can now check if the token is expired or not, and against the database.

## Navigation

The user use "live navigation" when online between two pages which use the same _live_session_, with no full page reload.

When the user goes offline, we have the same smooth navigation thanks to navigation hijack an the HTML and assets caching, as well as the usage of `y-indexeddb`.

When the user reconnects, we have a full-page reload.

This is implemented in [navigate.js](https://github.com/dwyl/PWA-Liveview/blob/main/assets/js/utilities/navigate.js).

**Lifecycle**:

- Initial Load: App start the LiveSocket and attaches the hooks. It will then trigger a continous server check.
- Going Offline: Triggers component initialization and navigation setup
- Navigating Offline: cleans up components, _fetch_ the cached pages (request proxied by the SW and the page are cached iva the `additionalManifestEntries`), parse ahd hydrate the DOM to renders components
- Going Online: when the polling detects a transistion off->on, the user expects a page refresh and Phoenix LiveView reinitializes.

**Key point**:

- ⚠️ **memory leaks**:
  With this offline navigation, we never refresh the page. As said before, reactive components and subscriptions need to be cleaned before disposal. We store the cleanup functions and the subscriptions.

## Vite

Source: < https://vite.dev/guide/backend-integration.html>

All the client code is managed by `Vite` and done in the file [vite.config.js](https://github.com/dwyl/PWA-Liveview/blob/main/assets/vite.config.js).

### Package.json and `pnpm` workspace (nor not)

You can use workspace.
From the root folder, add a file "pnpm-workpsace.yaml" (not "yml" !).
You reference the "assets" folder and the "deps" folder.

```yaml
packages:
  - assets
  - deps/phoenix
  - deps/phoenix_html
  - deps/phoenix_live_view
```

Then go to the "assets"folder, and:

- run `pnpm init`, 
- add the packages you want, eg `pnpm add -D taildwindcss @tailwindcss/vite`.

```json
{
  "dependencies": {
    "phoenix": "workspace:*",
    "phoenix_html": "workspace:*",
    "phoenix_live_view": "workspace:*", 
    "topbar": "^3.0.0"
    };
  "devDependencies": {
    "vite": "npm:rolldown-vite@^6.3.21",
    "@tailwindcss/vite": "^4.1.11",
    "tailwindcss": "^4.1.11",
    "daisyui": "^5.0.43",
    [...]
  }
}
```

Then, return to the root folder and run `pnpm i`.

Alternatively, you may _not use workspace_ and set directly reference `phoenix` with:

```json
{
  "dependencies": {
    "phoenix": "file:../deps/phoenix",
    "phoenix_html": "file:../deps/phoenix_html",
    "phoenix_live_view": "file:../deps/phoenix_live_view",
  },
  "devDependencies": {
    [...]
  }
}
```

From the folder "assets", you can run `pnpm i` (and `pnpm add ...`).

### Phoenix live_reload

In "dev.exs", use the following in "config :liveview_pwa, LiveviewPwaWeb.Endpoint," to let `Phoenix` code reload listen to only `.ex |.heex` file changes (_no_ static asset):

```elixir
live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"lib/liveview_pwa_web/(controllers|live|components|router|channels)/.*\.(ex|heex)$",
      ~r"lib/liveview_pwa_web/.*/.*\.heex$"
    ]
  ],
```

### HMR in DEV mode

Besides the `live_reload`, there is a watcher configured in "config/dev.exs" which replaces, thus removes, `esbuild` and `tailwindCSS` (which are also removed from the mix deps).

The watcher below runs the `Vite` dev server on port 5173. It will listen _only_ to static assets changes (`.js`, `.svg`, ...)

```elixir
watchers: [
    pnpm: [
      "vite",
      "serve",
      "--mode",
      "development",
      "--config",
      "vite.config.js",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]
```

### "env" config

Add an assign "env":

```elixir
# config.exs
config :liveview_pwa, env: config_env()
```

and assign it in a live component and/or controller to pass the value:

```elixir
#xx_live.ex

socket |> assign(:env, Application.fetch_env!(:liveview_pwa, :env))
```

### Root layout in :dev/:prod setup

Modify the layout "root.html.heex" to:

- use the `Vite.ex` module to set the correct paths for the files
- bring in the `Vite` WebSocket _only in dev mode_ via the assign `@env`.

```elixir
<link
  :if={@env === :prod}
  rel="stylesheet"
  href={Vite.path("css/app.css")}
/>

<script
  :if={@env === :dev}
  type="module"
  nonce={assigns[:main_nonce]}
  src="http://localhost:5173/@vite/client"
>
</script>

<script
  defer
  nonce={assigns[:main_nonce]}
  type="module"
  src={Vite.path("js/main.js")}
>
</script>
```

### Tailwind v4

Tailwind is used as a plugin. You add `tailwindcss` and `@tailwindcss/vite` to your dev dependencies.

In the `Vite` config, it is set with the declaration:

```js
import tailwindcss from "@tailwindcss/vite";
[...]

// in `defineConfig`, add:
defineConfig({
    plugins: [
      tailwindcss(), 
      ...
    ],
  },
),
```

Then, in "css/app.css", you import tailwindcss and add the `@source` where you use Tailwind classes: HEEX and JS.

```css
@import tailwindcss source(none);
@source "../css";
@source "../**/.*{js, jsx}";
@source "../../lib/liveview_pwa_web/";
@plugin "daisyui";
@plugin "../vendor/heroicons.js";
```

where "heroicons.js" is set as (cf `phoenix 1.8`):

<details>
<summary>--- heroicons.js ---</summary>

```js
const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = plugin(function ({ matchComponents, theme }) {
  const iconsDir = path.join(__dirname, "../../deps/heroicons/optimized");
  const values = {};
  const icons = [
    ["", "/24/outline"],
    ["-solid", "/24/solid"],
    ["-mini", "/20/solid"],
    ["-micro", "/16/solid"],
  ];
  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
      const name = path.basename(file, ".svg") + suffix;
      values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
    });
  });
  matchComponents(
    {
      hero: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, "");
        content = encodeURIComponent(content);
        let size = theme("spacing.6");
        if (name.endsWith("-mini")) {
          size = theme("spacing.5");
        } else if (name.endsWith("-micro")) {
          size = theme("spacing.4");
        }
        return {
          [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--hero-${name})`,
          mask: `var(--hero-${name})`,
          "mask-repeat": "no-repeat",
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block",
          width: size,
          height: size,
        };
      },
    },
    { values }
  );
});
```

</details>
<br/>

### Resolve assets with Vite config

You will benefit from using the `resolve` config by using alias.
For example:

```js
import img from "@assets/images/img.web";

// or dynamic at runtime inside a function

const img = new URL("@assets/images/img.web`", import.meta.url).href;
```

### Optmise CSS with `lightningCSS` in prod mode

We use `lightningCSS` in the rollup options to further optimze the CSS. There is no need to bring in `autoprefixer` since it is built in (eg  "-webkit" for flex/grid or "-moz" for transitions are needed).

### Client Env

The env arguments are loaded with `loadEnv`.

1. Runtime access: `import.meta.env`
   The client env vars are set in the ".env" placed, placed in the "/assets" folder (origin client code) next to "vite.config.js".
   They need to be prefixed with `VITE_`.
   They is injected by `Vite` at _runtime_ when you use `import.meta.env`.
   In particular, we use `VITE_API_KEY` for `Maptiler` to render the vector tiles.

2. Compile access: `define`
   it is used at _compile time_ .
   The directive `define` is used to get _compile time_ global constant replacement. This is valuable for dead code elimination.
   For example:

   ```js
   define: {
     __API_ENDPOINT__: JSON.stringify(
       process.env.NODE_ENV === "production"
         ? "https://example.com"
         : "http://localhost:4000"
     );
   }
   [...]
   // NODE_ENV="prodution"
   // file.js
   if (__API__ENDPOINT__ !== "https://example.com") {
    // => dead code eliminated
   }
   ```

3. Docker:
   In the Docker build stage, you copy the "assets" folder.
   You therefor copy the ".env" file so the env vars variables are accessible at runtime.
   When you deploy, we need to set an env variable `VITE_API_KEY` which will be used to build the image.

### Static assets

We have two types of static assets:

- fingerprinted by Rolldown as shown below
- and not, such as icons, iamges related to the webmanifest, SEO files such as sitemap.xml or robotx.txt, and the service worker file "sw.js".

The "non-fingerprinted" asets are served by `Phoenix` directly by listing them in the `LiveviewPwaWeb.static_path()` function.

We modify "endpoint.ex" to accept these encodings:

```elixir
plug Plug.Static,
  encodings: [{"zstd", ".zstd"}],
  brotli: true,
  gzip: true,
  at: "/",
  from: :liveview_pwa,
  only: LiveviewPwaWeb.static_paths(),
  headers: %{
    "cache-control" => "public, max-age=31536000"
  }
  [...]
```

where:

```elixir
def static_paths,
  do: ~w(assets icons robots.txt sw.js manifest.webmanifest sitemap.xml)
```

We can them reference in the HEEX components as usual:

```elixir
<link rel="icon" href="icons/favicon-192.png" type="image/png" sizes="192x192" />
<link rel="manifest" href="/manifest.webmanifest" />
```

#### `Vite.ex` module

An `Elixir` file path resolving module.
This is needed to resolve the file path in dev or in prod mode.

<details>
<summary> --- Vite.ex module --- </summary>

```elixir
if Application.compile_env!(:liveview_pwa, :env) == :prod do
  defmodule Vite do
    @moduledoc """
    A helper module to manage Vite file discovery.

    It appends "http://localhost:5173" in DEV mode.

    It finds the fingerprinted name in PROD mode from the .vite/manifest.json file.
    """
    require Logger

    # Ensure the manifest is loaded at compile time in production
    def path(asset) do
      app_ name = :liveview_pwa
      manifest = get_manifest(app_name)

      case Path.extname(asset) do
        ".css" ->
          get_main_css_in(manifest)

        _ ->
          get_name_in(manifest, asset)
      end
    end

    defp get_manifest(app_name) do
      manifest_path = Path.join(:code.priv_dir(app_name), "static/.vite/manifest.json")

      with {:ok, content} <- File.read(manifest_path),
           {:ok, decoded} <- Jason.decode(content) do
        decoded
      else
        _ -> raise "Could not read or decode Vite manifest at #{manifest_path}"
      end
    end

    def get_main_css_in(manifest) do
      manifest
      |> Enum.flat_map(fn {_key, entry} ->
        Map.get(entry, "css", [])
      end)
      |> Enum.filter(fn file -> String.contains?(file, "main") end)
      |> List.first()
    end

    def get_name_in(manifest, asset) do
      case manifest[asset] do
        %{"file" => file} -> "/#{file}"
        _ -> raise "Asset #{asset} not found in manifest"
      end
    end
  end
else
  defmodule Vite do
    def path(asset) do
      "http://localhost:5173/#{asset}"
    end
  end
end
```

</details>
<br/>

#### Static copy

We use the plugin `vite-plugin-static-copy` to let Vite copy the selected ones (eg the folder "assets/seo/{robots.txt, sitemap.xml}" or "/assets/icons") into the folder "/priv/static".

When the asset reference is versioned, we use the `.vite/manifest` dictionary to find the new name.
We used a helper [ViteHelper](https://github.com/dwyl/PWA-Liveview/blob/main/lib/soldiyjsweb/vite_helper.ex) to map the original name to the versioned one (the one in "priv/static/assets") 

#### DEV mode

In DEV mode, the helper will preprend the file name with `http://localhost:5173` because they are served by Vite DEV server.

#### PROD mode

Vite will build the assets. They are fingerprint (and compressed). This is set in `rollupOptions.output`:

```js
rollupOptions.output: mod === 'production' && {
  assetFileNames: 'assets/[name]-[hash][extname]',
  chunkFileNames: 'assets/[name]-[hash].js',
  entryFileNames: 'assets/[name]-[hash].js',
},
```

We do this because we want the SW to be able to detect client code changes and update the app. The Phoenix work would interfer.

Therefor, we do not use the step `mix phx.digest` and removed from the `Dockerfile`.

We also compress files to _ZSTD_ known for its compression performance and deflating speed. We use the plugin `vite-plugin-compression2` and use `@mongodb-js/zstd`.

### Performance optimisation: Dynamic CSS loading

`Leaflet` needs his own CSS file to render properly. Instead of loading all CSS upfront, the app dynamically loads stylesheets only when nd where needed. This will improve Lighthouse metrics.

We used a CSS-in-JS Pattern for Conditional Styles.
Check <https://github.com/dwyl/PWA-Liveview/blob/main/assets/js/components/initMap.js>

### VitePWA plugin and Workbox Caching Strategies

We use the [VitePWA](https://vite-pwa-org.netlify.app/guide/) plugin to generate the SW and the manifest.

The client code is loaded in a `<script>`. It will load the SW registration when the event DOMContentLoaded fires.
All of the hooks are loaded and attached to the LiveSocket, like an SPA.
If we don't _preload_ the JS files in the SW, most of the js files will never be cached, thus the app won't work offline.

For this, we define that we want to preload all static assets in the directive `globPattern`.

Once the SW activated, you should see (in dev mode):

<img width="548" alt="Screenshot 2025-02-26 at 16 56 40" src="https://github.com/user-attachments/assets/932c587c-908f-4e47-936a-7a191a35c892" />
<br/>

We also cache the rendered HTML pages as we inject them when offline, via `additionalManifestEntries`.

```js
PWAConfig = {
  // Don't inject <script> to register SW (handled manually)
  // and there no client generated "index.html" by Phoenix
  injectRegister: false, // no client generated "index.html" by Phoenix

  // Let Workbox auto-generate the service worker from config
  strategies: "generateSW",

  // App manually prompts user to update SW when available
  registerType: "prompt",

  // SW lifecycle ---
  // Claim control over all uncontrolled pages as soon as the SW is activated
  clientsClaim: true,

  // Let app decide when to update; user must confirm or app logic must apply update
  skipWaiting: false,

  workbox: {...}
}
```

❗️ It is important _not to split_ the "sw.js" file because `Vite` produces a fingerprint from the splitted files. However, Phoenix serves hardcoded nmes and can't know the name in advance.

❗️ You don't want to cache pages with Wrrokbox but instead trigger a "manual" cache. This is because you will get a CSRF mismatch as the token will be outdated. However, you want to pre-cache static assets so you cache the first page "Login" here.

```js
workbox: {
  // Disable to avoid interference with Phoenix LiveView WebSocket negotiation
  navigationPreload: false

  // ❗️ no fallback to "index.html" as it does not exist
  navigateFallback: null

  // ‼️ tell Workbox not to split te SW as the other is fingerprinted, thus unknown to Phoenix.
  inlineWorkboxRuntime: true,

  // preload all the built static assets
  globPatterns: ["assets/**/*.*"],

  // this will preload static assets during the LoginLive mount.
  // You can do this because the login will redirect to a controller.
  additionalManifestEntries: [
    { url: "/", revision: `${Date.now()}` }, // Manually precache root route
  ],

}
```

For the Service Worker lifecycle, set:

```js
defineConfig = {
  // Disable default public dir (using Phoenix's)
  publicDir: false,
};
```

## Yjs

[TODO something smart...?]

## Misc

### Presence through Live-navigation

It is implemented using a `Channel` and a `JavaScript` snippet used in the main script.

The reason is that if we implement it with `streams`, it will wash away the current stream
used by `Phoenix.Sync`.

It also allows to minimise rendering when navigating to the different Liveviews.

The relevant module is: `setPresenceChannel.js`. It uses a reactive JS component (`SolidJS`) to render updates.
It returns a "dispose" and an "update" function.

This snippet runs in "main.js".

The key points are:

- a Channel with `Presence.track` and a `push` of the `Presence.list`,
- use the `presence.onSync` listener to get a `Presence` list up-to-date and render the UI with this list
- a `phx:page-loading-stop` listener to udpate the UI when navigating between Liveviews because we target DOM elements to render the reactive component.

### Manifest

The "manifest.webmanifest" file will be generated from "vite.config.js".

Source: check [PWABuilder](https://www.pwabuilder.com)

```json
{
  "name": "LivePWA",
  "short_name": "LivePWA",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "lang": "en",
  "scope": "/",
  "description": "A Phoenix LiveView PWA demo app",
  "theme_color": "#ffffff",
  "icons": [
    { "src": "/images/icon-192.png", "sizes": "192x192", "type": "image/png" },
    ...
  ]
}
```

✅ Insert the links to the icons in the (root layout) HTML:

```html
<!-- root.html.heex -->
<head>
  [...] 
  <link rel="icon-192" href={~p"icons/icon-192.png"}/>
  <link rel="icon-512" href={~p"icons/icon-512.png"}/>
  <link rel="manifest" href={~p"/manifest.webmanifest"}/> 
</head>
```

### Page Caching

We want to cache HTML documents to render offline pages.

If we cache pages via Workbox, we will save an outdated CSRF token and the LiveViews will fail.

We need to cache the visited pages. We use `phx:navigate` to trigger the caching:

> It is important part is to calculate the "Content-Length" to be able to cache it.

```javascript
// Cache current page if it's in the configured routes
async function addCurrentPageToCache(path) {
  await navigator.serviceWorker.ready;
  await new Promise((resolve) => setTimeout(resolve, 100));
  // const url = new URL(path, window.location.origin).pathname;

  const htmlContent = document.documentElement.outerHTML;
  const contentLength = new TextEncoder().encode(htmlContent).length;

  const response = new Response(htmlContent, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Content-Length": contentLength,
    },
    status: 200,
  });

  const cache = await caches.open("page-shells");
  return cache.put(path, response.clone());
}
```

## Publish

The site <https://docs.pwabuilder.com/#/builder/android> helps to publish PWAs on Google Play, Ios and other plateforms.

## Postgres setup to use Phoenix.Sync

You need:

- set `wal-level logical`
- assign a role `WITH REPLICATION`

The first point is done by configuring your Postgres machine (check a local example in the "docker-compsoe.yml").

The second point is done via a migration (`ALTER ROLE postgres WITH REPLICATION`).

Check <https://github.com/dwyl/PWA-Liveview/issues/35> for the Fly launch sequence.

## Fly volumes

In the "fly.toml", the settings for the volume are:

```toml
[env]
DATABASE_PATH = '/data/db/main.db'


[[mounts]]
source = 'db'
destination = '/data'
```

This volume is made persistent through build with `source = 'name'`.
We set the Fly secret: `DATABASE_PATH=mnt/db/main.db`.

## Documentation source

- Update API: <https://docs.yjs.dev/api/document-updates#update-api>
- Event handler "on": <https://docs.yjs.dev/api/y.doc#event-handler>
- local persistence with IndexedDB: <https://docs.yjs.dev/getting-started/allowing-offline-editing>
- Transactions: <https://docs.yjs.dev/getting-started/working-with-shared-types#transactions>
- Map shared type: <https://docs.yjs.dev/api/shared-types/y.map>
- observer on shared type: <https://docs.yjs.dev/api/shared-types/y.map#api>

## Resources

Besides Phoenix LiveView:

- [Vite backend integration](https://vite.dev/guide/backend-integration.html)
- [Yjs Documentation](https://docs.yjs.dev/)
- [Vite PWA Plugin Guide](https://vite-pwa-org.netlify.app/guide/)
- [MDN PWA](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Best_practices)
- [PWA builder](https://www.pwabuilder.com/reportcard?site=https://solidyjs-lively-pine-4375.fly.dev/)
- [Favicon Generator](https://favicon.inbrowser.app/tools/favicon-generator) and <https://vite-pwa-org.netlify.app/assets-generator/#pwa-minimal-icons-requirements>
- [CSP Evaluator](https://csp-evaluator.withgoogle.com/)
- [Haversine formula](https://en.wikipedia.org/wiki/Haversine_formula)

## License

[MIT License](LICENSE)

## Enhance

To enhance this project, you may want to use the library `y_ex`, the `Elixir` port of `y-crdt`.

Credit to: [Satoren](https://github.com/satoren) for [Yex](https://github.com/satoren/y_ex)
