# 12 — Performance

**Purpose:** Preserve measured performance limits and deliberate tradeoffs when evidence exists.

**Confidence note:** Verified against all available project files on 2026-11-12. The code wins (see 16).

No benchmarks, service-level objectives, capacity limits, profiling results, hot paths, or known deliberate inefficiencies are present. Latency, throughput, client memory, database query cost, and offline behavior are unknown. Do not add performance constraints or optimize based on assumptions. Once implementation and production measurements are available, record the measurement method, workload, hard limit, and what breaks when it is exceeded.
