# OpenSearch Dashboard POC

Real-time telemetry and order lifecycle monitoring powered by **OpenSearch**, **Logstash**, and **OpenSearch Dashboards**.

---

## 🏛️ Architecture Overview

```mermaid
graph LR
    OracleDB[(Oracle DB<br/>CWORDERINSTANCE)] -->|JDBC Polling & Tracking<br/>NVL(LASTUPDATEDDATE, CREATIONDATE)| Logstash[Logstash Pipeline<br/>eoc-orders.conf]
    Logstash -->|Document Upsert<br/>@timestamp = CREATIONDATE| OpenSearch[(OpenSearch 2.x<br/>Index: eoc-orders)]
    OpenSearch -->|Dynamic Aggregations & Queries| Dashboards[OpenSearch Dashboards<br/>Executive Snapshot]
```

1. **Oracle Database**: Stores order instance records in `CWORDERINSTANCE`.
2. **Logstash Pipeline (`eoc-orders.conf`)**:
   - Incremental polling using JDBC input.
   - Dynamic tracking of `NVL(LASTUPDATEDDATE, CREATIONDATE)` to capture newly created and updated orders.
   - Computes state flags (`is_completed`, `is_executing`, `is_failed`) and duration metrics (`completion_seconds`).
   - Ingests into OpenSearch with `document_id => "%{order_id}"` for state upserts and `@timestamp` derived from `CREATIONDATE`.
3. **OpenSearch & Dashboards**:
   - `eoc-orders-pattern` index pattern based on `@timestamp`.
   - Real-time dynamic aggregation across user-selected time ranges (e.g. Last 15 min, Last 24 hours, Last 1 year, custom date filters).

---

## 📊 Executive Snapshot Metrics

| Metric Card | Aggregation / Filter | Description |
|---|---|---|
| **Orders Created** | `count(*)` | Total orders created within the selected time window. |
| **Completed** | `count(*) WHERE is_completed = true` | Orders successfully fulfilled. |
| **Executing** | `count(*) WHERE is_executing = true` | Orders currently in-flight / processing. |
| **Failed / Fallout** | `count(*) WHERE is_failed = true` | Orders in error or fallout states. |
| **Peak Throughput** | `max_bucket(date_histogram(1m))` | Peak order creation rate per minute in selected range. |
| **P95 Completion** | `percentiles(completion_seconds, 95)` | 95th percentile order processing duration (seconds). |

---

## 📁 Repository Structure

```
.
├── docker-compose.yml              # Multi-node OpenSearch, Dashboards, and Logstash cluster
├── .env.example                    # Sample environment variables
├── .gitignore                      # Excludes runtime state, secrets, and large dumps
├── dashboards/
│   ├── saved_objects.ndjson        # Exported Dashboards, Index Patterns, and Visualizations
│   └── import_dashboards.ps1       # Script to import saved objects across tenants (Global / Admin)
├── logstash/
│   ├── config/
│   │   └── logstash.yml            # Logstash configuration
│   ├── drivers/
│   │   └── ojdbc8.jar              # Oracle JDBC driver
│   ├── jdbc_last_run/              # Timestamp tracking metadata
│   └── pipeline/
│       └── eoc-orders.conf         # Main ingestion and transformation pipeline
└── README.md
```

---

## 🚀 Getting Started

### 1. Environment Configuration

Copy `.env.example` to `.env` and set the required passwords:

```bash
cp .env.example .env
```

### 2. Start Services

```bash
docker-compose up -d
```

Verify service status:
- OpenSearch: `https://localhost:9200`
- OpenSearch Dashboards: `http://localhost:5601`

### 3. Import Dashboards

Run the import script to load the saved objects across tenants:

```powershell
./dashboards/import_dashboards.ps1
```

Or import manually via OpenSearch Dashboards: **Stack Management** → **Saved Objects** → **Import** (`dashboards/saved_objects.ndjson`).
