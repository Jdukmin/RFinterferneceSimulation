# ICD — PairResult & MatrixResult

Requirements: SR-091…SR-093, AR-070…AR-081, DR-060…DR-062. (Task §24, §25.)

---

## 1. Reference planes (canonical — SR-112, Task §21)

| Symbol | Reference plane |
|--------|-----------------|
| `power_dBm` (TX) | TX antenna **input** port |
| EIRP reference | `power_dBm + txGain_dBi` at the radiated far-field reference (screening only) |
| `rxGain_dBi` | RX antenna, gain toward TX |
| Received-power screening | **RX antenna output port** = receiver RF input (before LNA) |
| `interferenceThreshold_dBm` | receiver RF input (unless a front-end relocates it) |

Phase-1 pattern-only mode does **not** produce a physical received power (no verified path loss);
it produces a *screening index* referenced to the RX antenna port with validity
`FAR_FIELD_NOT_VERIFIED` when a distance-based figure is requested.

## 2. `results.PairResult`

| Field | Type | Unit | Frame | Meaning / Missing |
|-------|------|------|-------|-------------------|
| `txId` | char | — | — | transmitter id |
| `rxId` | char | — | — | receiver id |
| `txAntennaId` | char | — | — | TX antenna id |
| `rxAntennaId` | char | — | — | RX antenna id |
| `distance_m` | double | m | B | TX↔RX separation; `NaN` if coincident |
| `txAz_deg` | double | deg | TX-A | TX→RX azimuth in TX frame |
| `txEl_deg` | double | deg | TX-A | TX→RX elevation |
| `txGain_dBi` | double | dBi | — | TX gain toward RX; `NaN` if out-of-domain |
| `rxAz_deg` | double | deg | RX-A | RX→TX azimuth in RX frame |
| `rxEl_deg` | double | deg | RX-A | RX→TX elevation |
| `rxGain_dBi` | double | dBi | — | RX gain toward TX; `NaN` if out-of-domain |
| `txLobeClass` | char (LobeClass) | — | — | `MAIN`/`SIDE`/`BACK` (metadata) |
| `rxLobeClass` | char (LobeClass) | — | — | metadata |
| `frequencyRelation` | char (FrequencyRelationType) | — | — | `IN_BAND`/`ADJACENT_BAND`/`OUT_OF_BAND` |
| `overlap_Hz` | double | Hz | — | spectral overlap |
| `couplingModelType` | char (CouplingModelType) | — | — | e.g. `PATTERN_ONLY` |
| `couplingMetric_dB` | double | dB | — | e.g. DirectionalCouplingIndex |
| `couplingMetricName` | char | — | — | metric name (prevents misreading) |
| `isPhysicalCoupling` | logical | — | — | `false` for pattern-only |
| `interferenceType` | char (InterferenceType) | — | — | Phase-1: `IN_BAND`/`ADJACENT_BAND`/`NONE` |
| `interferenceMetric_dB` | double | dB | — | screening metric (see §3); `NaN` if N/A |
| `margin_dB` | double | dB | — | `threshold − metric`; `NaN` if no receiver threshold |
| `validity` | char (ResultValidity) | — | — | primary validity |
| `confidence` | double | — | — | [0,1]; screening confidence |
| `riskLevel` | char (RiskLevel) | — | — | `NA`/`OK`/`LOW`/`WARN`/`HIGH` |
| `provenance` | struct | — | — | pattern provenances (txPatternProvenance, rxPatternProvenance) |
| `warnings` | cellstr | — | — | accumulated warnings (never dropped) |

### Reserved fields (declared, `NaN`/empty in Phase 1 — SR-091, Task §24)
`ItoN_dB`, `CtoNplusI_dB`, `receiverInputPower_dBm`, `blockingMargin_dB`, `p1dBMargin_dB`,
`im3Margin_dB`, `measuredS21_dB`. These are structural extension points; Phase 1 leaves them
`NaN` (never invented, SR-120).

## 3. Phase-1 interference metric (screening semantics)

- **Pattern-only (default):** `interferenceMetric_dB = txPower_dBm + DirectionalCouplingIndex_dB`
  = `txPower_dBm + txGain_dBi + rxGain_dBi`. This is an **upper-bound screening index at the RX
  antenna port with no path loss**, labeled `couplingMetricName='DirectionalCouplingIndex_dB'`
  and carried with validity `FAR_FIELD_NOT_VERIFIED` (because no verified separation loss is
  applied). It is explicitly **not** received power (rule 1, SR-003).
- If `interferenceThreshold_dBm` present: `margin_dB = interferenceThreshold_dBm −
  interferenceMetric_dB`; else `margin_dB = NaN`, validity includes `MISSING_RECEIVER_DATA`.
- If TX/RX are frequency `OUT_OF_BAND`, `interferenceType=NONE` and the metric is still reported
  (with risk downgraded), because out-of-band energy can still matter for blocking (reserved).

## 4. Validity selection (canonical precedence)

The primary `validity` is chosen by first applicable rule:
1. pattern lookup out-of-domain (either side) → `OUTSIDE_PATTERN_DOMAIN`.
2. in-band & no receiver threshold → `MISSING_RECEIVER_DATA`.
3. in-band & high directional index (pattern-only) → `REQUIRES_FULL_WAVE_VERIFICATION`.
4. far-field figure requested but not verified → `FAR_FIELD_NOT_VERIFIED`.
5. otherwise → `VALID_PATTERN_SCREENING`.

Multiple applicable conditions are also appended to `warnings` (nothing dropped, AR-081).

## 5. `results.MatrixResult`

| Field | Type | Meaning |
|-------|------|---------|
| `txIds` | cellstr | row keys (ordered) |
| `rxIds` | cellstr | column keys (ordered) |
| `pairs` | cell (nTx×nRx) | `PairResult` per cell; `[]` for self-pair |
| `risk` | cell (nTx×nRx) of char | `RiskLevel` per cell (`NA` on self-pair diagonal) |
| `scenarioName` | char | source scenario |
| `couplingModelType` | char | model used |
| `generatedFields` | struct | run metadata (config summary) |

Accessors: `getPair(txId,rxId)`, `riskOf(txId,rxId)`, `highRiskPairs()` (list of (txId,rxId)
with `HIGH`). The matrix is a plain serializable structure (no live handles, DR-062).

## 6. Example (illustrative, from synthetic fixtures — not mission data)

```
              RX1     RX2     RX3
   TX1        NA      HIGH    OK
   TX2        LOW     NA      WARN
   TX3        OK      LOW     NA
```
Diagonal `NA` = TX and RX share an antenna/system (self-pair not analyzed, AR-073).
