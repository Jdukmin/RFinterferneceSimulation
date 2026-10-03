# Receiver nonlinear data search — S-band transponder, GNSS receiver, X-band ISL receiver (P7d-6)

Date: 2026-10-04. Goal: find published P1dB / IIP3 / blocking data for the three receiver classes
of the RFC baseline and apply them. **Result: no such values were found; P1dB/IIP3 stay unknown
(NaN) in `rf_systems.csv`.** The data path is implemented and tested, so a datasheet value is a
one-row change (see below).

## What was searched and found

| Receiver | Sources checked | Published nonlinear data found |
|----------|-----------------|--------------------------------|
| S-band TC receiver (MSBT) | [IEEE: MSBT Transponder — flexible multi-mode in-orbit reconfigurable transponder](https://ieeexplore.ieee.org/document/8541720/) (page text not retrievable); [NTRS 20205002496](https://ntrs.nasa.gov/citations/20205002496) (abstract only); search summaries | **None.** Public text gives only qualitative statements: multi-modulation / multi-frequency, "jammer resistant design", suppressed-carrier BPSK above 2 Mbps in the telecommand receiver. |
| GNSS receiver (PODRIX) | [Beyond Gravity PODRIX datasheet PDF](https://www.beyondgravity.com/sites/default/files/media_document/2024-04/BG_PODRIX_GNSS_Receiver%20spaceborne_Satellite_RX_V1.0.pdf) and a mirror at SatCatalog | **Could not be read.** Both PDFs came back as artwork metadata (no extractable text). Search summaries list only qualitative front-end features (internal LNAs, selective RF filter + LNA) and the supported signals (L1 C/A, L2C, L5, E1, E5a, E6). |
| X-band ISL receiver | generic search | **None.** No ISL modem/receiver is selected, so there is nothing to look up; generic X-band LNA catalogue parts (e.g. 10.1–11.7 GHz LNAs) are component data, not a receiver specification, and were **not** used. |

## Notes for the owner

- Sources attribute the MSBT to **Thales Alenia Space in Spain** (TAS-E); the request named TASI.
  Please confirm the vendor/part before requesting data.
- The PODRIX PDF is the one most worth re-checking by hand (it is a public datasheet, but the
  automated read failed); a human reading it may find noise figure / maximum input power /
  jamming tolerance. A vendor-supplied interface or jamming-immunity document is the realistic
  source for blocking data.
- Component catalogue values must not stand in for a receiver specification; if they are used
  they must be tagged `ENGINEERING_ASSUMPTION` (never `DATASHEET`).

## How to apply data when it is available

In `data/spacecraft/simplified_spacecraft_v1/rf_systems.csv`, on the RX row:

1. fill `p1db_in_dbm` and/or `iip3_in_dbm` (input-referred to the LNA input, dBm);
2. set `frontend_prov` (`DATASHEET`, `MEASURED`, `SIMULATED`, `USER_INPUT`) — **mandatory**, the
   build fails otherwise.

`MissionCaseBuilder` then creates a `ReceiverFrontEnd` for that receiver. **No** compression
backoff, blocking allowance or IM3 criterion is created from these columns (none is known); the
nonlinear analyzers will keep reporting `MISSING_*_CRITERION` until criteria are supplied.
