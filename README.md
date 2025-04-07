Project documentation:
https://photonenergyco-my.sharepoint.com/personal/martin_buhler_photonenergy_com/_layouts/Doc.aspx?sourcedoc={12A9730B-5601-4F9F-9F22-1D2FC9D478D3}&end=()
onenote:https://photonenergyco-my.sharepoint.com/personal/martin_buhler_photonenergy_com/Documents/Documents/Code/informania/informania/

Project structure:

```
project-root/
│
├── backend/                          # Python backend
│   ├── main.py                       # FastAPI/Flask entry point
│   ├── db.py                         # LMDB interactions
│   ├── zig_wrapper.py                # Calls Zig library
│   ├── requirements.txt              # Python dependencies
│   ├── notebooks/                    # Jupyter Notebooks
│   │   ├── example_notebook.ipynb    # Example notebook for interacting with API/LMDB
│   ├── tests/                        # Backend tests
│   │   ├── test_api.py               # API tests
│   │   ├── test_db.py                # LMDB database tests
│   │   ├── test_zig.py               # Zig integration tests
│   ├── setup.sh                      # Linux setup script
│   └── Dockerfile                    # Backend containerization
│
├── frontend/                         # Svelte frontend
│   ├── src/                          # Svelte source code
│   ├── bun.lockb                     # Bun lockfile
│   ├── bunfig.toml                   # Bun configuration
│   ├── package.json                  # Dependencies (Bun-managed)
│   ├── svelte.config.js              # SvelteKit config
│   ├── vite.config.js                # Vite config (if needed)
│   ├── tsconfig.json                 # TypeScript config
│   ├── tests/                        # Frontend tests
│   │   ├── test_components.spec.js   # Svelte component tests
│   │   ├── test_routes.spec.js       # Page routing tests
│   ├── setup.sh                      # Linux setup script
│   ├── Dockerfile                    # Frontend containerization
│   └── README.md                     # Frontend documentation
│
├── zig-core/                         # Zig high-performance module
│   ├── src/                          # Zig source code
│   │   ├── lib.zig                   # Zig functions
│   │   ├── build.zig                 # Zig build script
│   ├── zig-out/                      # Compiled shared libraries
│   ├── tests/                        # Zig tests
│   │   ├── test_lib.zig              # Unit tests for Zig functions
│   ├── setup.sh                      # Zig setup script
│   └── Dockerfile                    # Zig containerization
│
├── docker/                           # Docker orchestration (multi-container, compose, etc.)
│   ├── docker-compose.yml            # Compose file to run whole stack
│   ├── backend.env                   # Backend environment variables
│   ├── frontend.env                  # Frontend environment variables
│   ├── zig.env                       # Zig environment variables (if needed)
│   └── README.md                     # Notes on how to use Docker for this project
│
├── scripts/                          # Development & automation scripts
│   ├── run_tests.sh                  # Run all tests (backend, frontend, Zig)
│   ├── start.sh                      # Start backend & frontend
│   ├── build.sh                      # Build all components
│   ├── test.sh                       # Run specific tests
│   ├── setup_all.sh                  # Setup script for all components
│
├── jenkins/                          # Jenkins CI/CD configuration
│   ├── Jenkinsfile                   # Main Jenkins pipeline definition
│   ├── backend.groovy                # Optional: backend-specific steps
│   ├── frontend.groovy               # Optional: frontend-specific steps
│   ├── zig.groovy                    # Optional: zig-core-specific steps
│   └── shared_libs/                  # Shared pipeline libraries (optional)
│
├── .gitignore                        # Ignore unnecessary files
├── README.md                         # Project documentation
└── setup.sh                          # Root-level setup script
```