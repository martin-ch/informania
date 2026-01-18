Project documentation:
https://photonenergyco-my.sharepoint.com/personal/martin_buhler_photonenergy_com/_layouts/Doc.aspx?sourcedoc={12A9730B-5601-4F9F-9F22-1D2FC9D478D3}&end=()
onenote:https://photonenergyco-my.sharepoint.com/personal/martin_buhler_photonenergy_com/Documents/Documents/Code/informania/informania/

Project structure:

```
Project structure:

```
yourapp/
├─ README.md
├─ .gitignore
├─ .env.example                          # templates only; never real secrets
├─ Makefile                              
├─ docker-compose.yml                    # local dev: proxy + streamlit + api + supertokens + postgres
├─ ops/
│  ├─ reverse-proxy/
│  │  ├─ caddy/
│  │  │  ├─ Caddyfile                   # /, /api, /auth, TLS (auto)
│  │  │  └─ Dockerfile
│  │  └─ nginx/
│  │     ├─ app.conf                    # alt to Caddy; includes WS upgrade for Streamlit
│  │     └─ Dockerfile
│  ├─ k8s/                               # optional: production manifests
│  │  ├─ streamlit-deploy.yaml
│  │  ├─ api-deploy.yaml
│  │  ├─ proxy-deploy.yaml
│  │  ├─ supertokens-deploy.yaml
│  │  ├─ postgres-statefulset.yaml
│  │  ├─ secrets-store/                  # External Secrets / CSI (if used)
│  │  └─ ingress.yaml
│  ├─ pgbouncer/
│  │  ├─ pgbouncer.ini
│  │  └─ userlist.txt                    # not in Git in real envs
│  └─ ci/
│     └─ github-actions/
│        ├─ build_ui.yml
│        ├─ build_api.yml
│        └─ deploy.yml                   # OIDC to cloud; fetch secrets at deploy time
│
├─ ui/                                   # Streamlit (UI only: RO DB reads; no writes)
│  └─ streamlit/
│     ├─ app.py
│     ├─ peg_login.py                    # your authenticate_user() gate (fail‑closed)
│     ├─ pages/
│     │  ├─ 01_Dashboard.py
│     │  ├─ 02_Reports.py
│     │  └─ 03_Trades.py                 # still UI-only; any write calls go to /api
│     ├─ components/
│     │  ├─ auth_gate.py                 # thin wrapper around peg_login.authenticate_user()
│     │  ├─ tables.py
│     │  └─ charts.py
│     ├─ services/
│     │  ├─ ro_db.py                     # psycopg / asyncpg reads; sets app.user_id GUC
│     │  ├─ api_client.py                # requests to FastAPI (/api/*)
│     │  └─ models.py                    # DTOs used in UI only
│     ├─ assets/
│     │  ├─ styles.css
│     │  └─ logo.png
│     ├─ config.toml
│     ├─ requirements.in
│     ├─ requirements.txt
│     └─ tests/
│        └─ ui_smoke_test.py
│
├─ backend/                              # FastAPI (writes, LMDB, trading, audits)
│  ├─ pyproject.toml
│  ├─ src/app/
│  │  ├─ main.py                         # FastAPI app/routers
│  │  ├─ core/
│  │  │  ├─ settings.py                  # loads env; no secrets hardcoded
│  │  │  ├─ logging.py
│  │  │  └─ security.py                  # SuperTokens session verification decorator
│  │  ├─ auth/
│  │  │  ├─ supertokens_middleware.py    # protect /api routes server-side
│  │  │  └─ rbac.py                      # role checks (viewer/trader/admin)
│  │  ├─ api/
│  │  │  ├─ routes/
│  │  │  │  ├─ health.py
│  │  │  │  ├─ orders.py                 # write-only; idempotent SP; audit + outbox
│  │  │  │  ├─ lmdb.py                   # LMDB get/put (writer lock for put)
│  │  │  │  └─ data.py                   # safe write endpoints (if any)
│  │  │  └─ __init__.py
│  │  ├─ services/
│  │  │  ├─ db.py                        # SQLAlchemy/asyncpg (write role + pool)
│  │  │  ├─ sp.py                        # stored procedure helpers (idempotency keys)
│  │  │  ├─ lmdb_actor.py                # single-writer semaphore; RO transactions without lock
│  │  │  ├─ qc_client.py                 # QuantConnect integration
│  │  │  └─ ibkr_adapter.py              # (behind QC if needed)
│  │  ├─ models/
│  │  │  ├─ dto.py
│  │  │  └─ orm.py
│  │  ├─ outbox/
│  │  │  ├─ schema.sql                   # events_outbox table (DDL)
│  │  │  └─ repo.py
│  │  └─ audits/
│  │     ├─ schema.sql                   # append-only audit log
│  │     └─ repo.py
│  ├─ alembic/
│  │  ├─ env.py
│  │  ├─ script.py.mako
│  │  └─ versions/
│  │     ├─ 20260109_init.py
│  │     └─ 20260109_timeseries.py
│  ├─ worker/                            # trading worker; consumes outbox
│  │  ├─ __main__.py
│  │  ├─ consumer.py
│  │  ├─ reconcilers.py
│  │  └─ pyproject.toml
│  ├─ zig-lmdb/                          # Zig→C ABI→Python for LMDB
│  │  ├─ build.zig
│  │  ├─ src/
│  │  │  ├─ lmdb_ffi.zig
│  │  │  ├─ hashtable.zig
│  │  │  └─ bridge.zig
│  │  ├─ include/lmdb.h
│  │  ├─ target/libzig_lmdb.so           # build artifact (ignored in Git)
│  │  └─ tests/hashtable_test.zig
│  ├─ Dockerfile
│  └─ tests/
│     ├─ unit/
│     └─ integration/
│
├─ auth/
│  └─ supertokens/
│     ├─ core-config/config.yaml         # SuperTokens Core config (no secrets checked in)
│     ├─ docker/Dockerfile
│     └─ README.md
│
├─ db/
│  ├─ postgres/
│  │  ├─ schemas/
│  │  │  ├─ 00_base.sql                  # users, accounts, strategies, etc.
│  │  │  ├─ 10_orders.sql                # orders, executions, positions
│  │  │  └─ 20_reporting.sql             # reporting views; Streamlit RO queries
│  │  ├─ security/
│  │  │  ├─ roles.sql                    # app_read (RO), app_write (RW)
│  │  │  ├─ rls_policies.sql             # optional row-level security
│  │  │  └─ grants.sql                   # strict grants on reporting schema
│  │  ├─ procedures/
│  │  │  ├─ sp_place_order.sql           # idempotent; uses client_order_id UNIQUE
│  │  │  ├─ sp_outbox_enqueue.sql
│  │  │  └─ sp_audit_append.sql
│  │  ├─ timeseries/
│  │  │  ├─ enable_timescaledb.sql
│  │  │  └─ hypertables.sql
│  │  └─ config/
│  │     ├─ postgresql.conf
│  │     └─ pg_hba.conf
│  └─ migrations/                         # optional raw SQL migrations
│
├─ scripts/
│  ├─ init_dev.sh                         # venv, pre-commit, local env scaffolding
│  ├─ build_zig_lmdb.sh
│  ├─ migrate.sh
│  ├─ seed_db.sh
│  └─ run_all.sh                          # docker compose up with dependencies
│
├─ secrets/                               # only templates; real secrets never in Git
│  ├─ templates/
│  │  ├─ streamlit.env.example           # RO DB DSN, API base URL
│  │  ├─ api.env.example                 # RW DB DSN, LMDB dir, QC/IBKR keys (placeholders)
│  │  └─ proxy.env.example               # email for ACME, etc.
│  └─ sops/README.md                     # if you adopt SOPS+KMS for GitOps
│
├─ tests/
│  ├─ e2e/
│  │  └─ e2e_place_order.py              # UI→API→outbox→QC→DB happy path
│  └─ load/
│     └─ locustfile.py
└─ docs/
   ├─ architecture.md                     # diagrams and flows
   ├─ auth.md                             # Streamlit gate + SuperTokens server-side verification
   ├─ data_model.md                       # schemas + RLS strategy
   ├─ lmdb.md                             # single-writer pattern; backups (copy_compact)
   ├─ proxy.md                            # Caddy/NGINX config notes
   └─ secrets.md                          # how secrets are pulled at deploy/runtime

```
```
