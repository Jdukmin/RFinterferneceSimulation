# Accepted-power validation checkpoint

Supersedes the matching hard-gate statement in acceptance_checkpoint.md under the user's latest steering. Active return loss is diagnostic only for this accepted-power surrogate; no matching-driven geometry refinement is justified.

SBA1 XZ results (YZ gives the same metrics to displayed precision), fixed IEEE LHCP sense:

| Frequency GHz | Coverage MAE dB | Peak error dB | Maximum coverage axial ratio dB |
|---|---:|---:|---:|
| 2.00 | 0.731 | 0.236 | 4.74 |
| 2.06 | 0.726 | 0.487 | 4.46 |
| 2.12 | 0.743 | 0.741 | 4.18 |
| 2.20 | 0.987 | 0.468 | 3.84 |
| 2.25 | 1.029 | 0.640 | 3.67 |
| 2.30 | 1.079 | 0.773 | 3.52 |

Authoritative numeric evidence: accepted_power_frequency_validation.json, raw cut CSVs, s_matrix.npz. The coverage is both sides of each canonical 1-degree cut through 90 degrees. Accepted-power gain corrects the coherent four-port realized gain by the total accepted incident-power fraction; this is not conducted-to-radiated transfer. Numerical normalization reliability is recorded per frequency.

The successful base mesh contains 79,376 cells according to the actual CST Model.log. A second refined mesh has not yet been solved, so convergence is unproven. Source-qualified anchor/envelope, coverage roll-off/axis, conservative export, actual CST screenshots and final pinned evidence remain pending. No overall RFC PASS is claimed.

All matching-only optimization is stopped. The analytic matching feasibility study is retained as diagnostic work, not acceptance evidence.
