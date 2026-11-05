/**
 * Histogram boundaries. Without them OTel uses 0, 5, 10, 25 … (milliseconds-style), which puts every
 * request in the first bucket of a seconds histogram and makes every quantile read ~4.75 s (S8 F2).
 */

/** Request and live-update latency: 10 ms to 10 s. */
export const LATENCY_BUCKETS_S = [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 3, 5, 10];

/** Time inside the conditional spot UPDATE: usually well under a millisecond, seconds under contention. */
export const DB_WAIT_BUCKETS_S = [0.0005, 0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5];
