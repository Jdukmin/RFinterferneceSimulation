# Fixed-geometry RFC frequency calculations

Owner-approved scope, 2026-10-04: keep antenna geometry and ports unchanged;
calculate each existing antenna at each potential interferer band. No separate
EM scan. Installed calculations are limited to S and L, and to meshes that fit
CST 2026 Learning Edition's strict <100,000 hexahedral-cell budget. ISL and Ka
use free-space patterns. SAR has no analysis-bound pattern yet; its frequency
band still serves as an evaluation band for other antennas.

## Corrected TX/RX queue

Latest owner correction: S and ISL support TX/RX; L supports RX only; Ka supports TX only. Remove KA_RX and L_TX jobs. ISL_RX remains required. Port excitation used to extract a receive response does not create an L transmitter. Existing responses are reused for reciprocal TX/RX roles.

## Case definitions

- Installed identities excluding Ka/SAR: SBA_NADIR/SBA_ZENITH times SBA1/SBA4
  references = 4; GPSA_1/GPSA_2 = 2; ISL = 1: **7**. Only the first six identities
  are installed candidates; ISL stays free-space under the later owner decision.
- Isolated identities excluding Ka/SAR: SBA1, SBA4, common GNSS, ISL: **4**;
  with Ka: **5**. The accepted CST S surrogate is shared; SBA1/SBA4 are separate
  reference patterns, not two newly invented antenna geometries.
- Eight evaluation bands: S-TC (2–2.12), S-TM (2.2–2.3), L1
  (1.563–1.588), L2 (1.21737-1.23783; existing assumed 20.46 MHz receiver window), L5 (1.164–1.189),
  ISL (10.55–10.65), SAR (8.9–10.4), Ka (25.5–27), all GHz.
- L1/L5 windows remain repository assumptions. L2 has no measured source
  pattern; compute the unchanged L geometry at 1.22760 GHz and retain the
  distinction from the original 1.207 GHz datasheet proxy. The three L2 monitors use the existing assumed receiver window.
- Low/center/high monitors start each nonzero-width band; they do not establish
  convergence over a frequency interval. SAR's initial center is 9.65 GHz.

## Completed ISL operating-band update

`cst/projects/ISL_FIXED_10G6.cst` uses the accepted cup-patch geometry unchanged,
four existing 50-ohm ports and phases 0/-90/-180/-270 degrees. Solve range
10.3–10.75 GHz; monitors 10.4, 10.55, 10.6, 10.65 GHz. Actual solver: **29,988
cells, 50 seconds, four successful excitations, no logged errors/warnings**.

| GHz | Accepted-power RHCP peak dBi | XZ HPBW degrees | Minimum active RL dB |
|---|---:|---:|---:|
| 10.55 | 10.112 | 58.772 | 6.758 |
| 10.60 | 10.142 | 58.527 | 7.157 |
| 10.65 | 10.173 | 58.283 | 7.556 |

At 10.6 vs original 10.4: peak +0.122 dB, HPBW -0.979 degrees, minimum
active RL +1.515 dB, 0–60-degree cut RMS difference 0.152 dB and maximum
absolute difference 0.382 dB. Recomputed 10.4 controls differed by only 0.0033
dB maximum in that coverage. The existing ASSUMED-template gates pass; this
is not manufacturer validation or a mesh-convergence claim.

New screening cuts are copied to `data/Xband_ISL/f10.55_*`, `f10.6_*`,
`f10.65_*`; old files are preserved. The active pattern binding is `ISL_10P6`,
10.55–10.65 GHz. Source evidence: `cst/results/ISL_FIXED_10G6/validation.json`
and `frequency_change_comparison.json`. Screening-envelope exports differ
from the raw physically calculated cuts; both are retained.

## Actual installed feasibility findings

The new sheet builder clips the actual SSOT facets and transforms them to each
antenna's unchanged right-handed local frame. No brackets/cables/radomes are
invented. Geometry tests verify physical planes, unchanged references, frame
orthogonality/handedness and finite-facet versus plane distances.

| Model | Included panels | lambda/8 starting cells | lambda/6 resource cells |
|---|---|---:|---:|
| SBA_NADIR, TM, R3 | 1 / 6 / rear 8 | 620,658 | 377,720 |
| GPSA_1, L1, R3 | 3 / 4 | 528,656 | 333,822 |

Further NADIR lambda/4 with ratio limit 10 still produces **171,808 cells**.
No over-limit installed solver was started. An installed pattern and extent
convergence are not established by these geometry/mesh attempts.

NADIR mount-plane / actual finite-facet distances: 190.181 / 245.838 mm;
rear plane / finite rear-facet: 255 / 354.205 mm. ZENITH: 161.739 / 280.173 mm;
rear: 255 / 378.843 mm. Both GPS references: panel-3 plane / finite facet
76.997 / 219.746 mm. GPS rear facets lie >2 m away and outside the L1 R3 crop.

## Batch outputs and limitations

`cst/run_rfc_frequency_cases.py` creates separate projects from unchanged
numeric definitions, verifies actual mesh lines/box/min/max steps before
solving, records actual solver-log counts and runtimes, and exports independent
1-degree XZ/YZ cuts with complex fields, total realized gain, accepted-power
gain, circular components and active-port diagnostics. The `(Nx-1)*(Ny-1)*(Nz-1)`
count was checked against the actual ISL solver log. No angular symmetry is
assumed. In raw case CSVs, use **gain_dbi** for accepted-power total gain;
**realized_gain_dbi** for incident-power-normalized gain.

Case status and diagnostics are written under
`cst/results/rfc_frequency_cases/`; `frequency_plan.json` defines the current
monitor matrix. A MESH_LIMIT status means no pattern was calculated, never a
zero-gain or frequency-independent substitute. Weak accepted power or S-matrix
passivity error flags unreliable accepted-power normalization explicitly.

The frozen original datasets remain separate from these new frequency-response
calculations. Outside their validated operating bands, new outputs describe
the **fixed surrogate**, not certified product response. Existing Ka ports
represent a feed-only model; the complete reflector pattern uses a non-CST
aperture calculation. Full Ka out-of-band port response is not established by
the S/L/ISL batch. SAR source-pattern generation remains deferred.

Installed-pattern import and R3/R4/R5 numerical comparison remain pending
because the attempted installed models exceed the mesh budget. No replacement
of InstalledPattern by a fabricated 3D interpolation from two installed cuts
has been made. MATLAB/Octave tests require an available runtime; Python geometry
tests pass (3 tests).
