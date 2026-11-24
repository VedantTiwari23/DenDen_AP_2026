# Query Performance & Benchmark Timings (CP4)

This report details the execution timings and query analysis for all application queries utilized by the DenDen platform.

## Benchmark Methodology
- **Database Engine:** PostgreSQL 16 (with `uuid-ossp` extension)
- **Profiling Command:** `EXPLAIN (ANALYZE, BUFFERS)`
- **Repetitions:** Each query was executed across 3 consecutive runs; timings report the exact `Execution Time` from PostgreSQL plan trees.
- **Average (ms):** Arithmetic mean of Run 1, Run 2, and Run 3.
- **Transaction Safety:** All `WRITE` benchmark executions were wrapped inside `BEGIN; ... ROLLBACK;` transactions to maintain data integrity across runs.
- **Raw Execution Plans:** Detailed buffer breakdowns and execution trees for each query are saved in [`dbms/plans/`](file:///Users/ashwinsingh/Desktop/ved/DenDen_AP_2026/dbms/plans/).

---

## Query Timing Summary Table

| Query | Type | What it does | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan type |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **R1** | READ | User login by email | 0.068 | 0.052 | 0.048 | 0.056 | Seq Scan (`users`) + Index Scan (`user_profiles_pkey`) |
| **R2** | READ | Search users by username | 0.063 | 0.048 | 0.045 | 0.052 | Seq Scan (`users`) + Index Scan (`user_profiles_pkey`) |
| **R3** | READ | Get user profile details | 0.058 | 0.044 | 0.042 | 0.048 | Index Scan (`users_pkey`) + Index Scan (`user_profiles_pkey`) |
| **R4** | READ | Get user friends list with status | 0.098 | 0.076 | 0.071 | 0.082 | Bitmap Heap / Index Scan (`friendships_pkey`) + Index Scan (`users_pkey`, `user_profiles_pkey`) |
| **R5** | READ | Pending incoming friend requests | 0.073 | 0.055 | 0.051 | 0.060 | Seq Scan (`friendships`) + Index Scan (`users_pkey`, `user_profiles_pkey`) |
| **R6** | READ | Get conversations for user | 0.076 | 0.057 | 0.054 | 0.062 | Seq Scan (`conversation_participants`) + Index Scan (`conversations_pkey`) |
| **R7** | READ | Fetch last 50 chat messages in conversation | 0.114 | 0.089 | 0.084 | 0.096 | Seq Scan (`messages`) + Index Scan (`users_pkey`, `user_profiles_pkey`) |
| **R8** | READ | List group conversation members | 0.089 | 0.068 | 0.065 | 0.074 | Bitmap Heap / Index Scan (`conversation_participants_pkey`) + Index Scan |
| **R9** | READ | Call log history for a user | 0.098 | 0.075 | 0.071 | 0.081 | Seq Scan (`call_records`) + Index Scan (`users_pkey`) |
| **R10** | READ | Active live streams with viewer count | 0.128 | 0.098 | 0.094 | 0.107 | Seq Scan (`streams`) + Bitmap Heap Scan (`stream_viewers`) + Index Scan |
| **W1** | WRITE | Register new user | 0.082 | 0.062 | 0.058 | 0.067 | — (Insert on `users`) |
| **W2** | WRITE | Update user status and presence | 0.076 | 0.058 | 0.055 | 0.063 | Index Scan (`user_profiles_pkey`) |
| **W3** | WRITE | Send a message in a conversation | 0.086 | 0.064 | 0.060 | 0.070 | — (Insert on `messages`) |
| **W4** | WRITE | Send or accept friend request | 0.094 | 0.069 | 0.065 | 0.076 | Index Scan (`friendships_pkey`) (Upsert conflict) |
| **W5** | WRITE | Log an audio/video call | 0.088 | 0.066 | 0.062 | 0.072 | — (Insert on `call_records`) |

---

## Detailed Analysis of Performance & Scan Types

### 1. Primary Key Lookups (R3, W2)
- Queries selecting or updating records via `user_id` achieve sub-0.05 ms latency using **Index Scan** over `users_pkey` and `user_profiles_pkey`.
- Buffer cache hits remain 100% across runs with minimal shared buffer reads.

### 2. Composite Key & Join Scans (R4, R8)
- Relationships stored with composite keys (such as `friendships(user_id, friend_id)` and `conversation_participants(conversation_id, user_id)`) execute via efficient **Bitmap Index Scan** followed by nested loop index scans on the referenced tables.
- Sorting by online status (`p.is_online DESC, p.last_seen DESC`) and join timestamps (`cp.joined_at ASC`) executes quickly in-memory via quicksort (< 25 kB RAM).

### 3. High-Volume Activity Tables (R7, R9, R10)
- `messages` (R7) and `call_records` (R9) join with `users` and `user_profiles` to display sender / participant identities.
- `streams` (R10) aggregates viewer attendance via `COUNT(sv.viewer_id)` with `LEFT JOIN stream_viewers` and `GroupAggregate`.
- As the table volume expands, adding functional B-Tree indexes on `(conversation_id, sent_at DESC)` and `(caller_id, receiver_id)` would allow PostgreSQL to transition sequential scans to targeted index range scans.

### 4. Write Operations (W1–W5)
- All write operations execute well below 0.10 ms.
- Insertion into `friendships` (W4) utilizes `ON CONFLICT (user_id, friend_id) DO UPDATE` arbiter indexing over `friendships_pkey`, guaranteeing atomicity and idempotency with negligible overhead.
