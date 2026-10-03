# Ka downlink modulation / data rate — open design issue (NOT an RFC input)

Status: **design discussion, outside the RFC/RFI SSOT.** Nothing in `data/` or the analysis
requirements depends on it. Separated from the RFC baseline on 2026-10-04 (P7d-1).

## What the RFC baseline uses

The Ka downlink transmitter (`KA_DLS_TX@KAA_1/2`) is modelled for coexistence screening as:
fc = 26.25 GHz, occupied bandwidth **1.5 GHz = 25.50–27.00 GHz** (the full near-Earth EESS
allocation), 70 W = 48.45 dBm. The bandwidth is an **allocation-filling engineering assumption**,
chosen so that no part of the allocation is left unscreened. It is not derived from a modulation
or a data rate.

## The open question (kept here, not in the SSOT)

An earlier draft derived 1.44 GHz from 1.2 Gsym/s with RRC α = 0.2 (1.2·(1+0.2)). Separately, a
10 Gbps user-data requirement was mentioned. With single-carrier 64APSK the raw maximum at
1.2 Gsym/s is 6 × 1.2 = 7.2 Gbit/s before FEC, so 10 Gbps cannot be met by that configuration;
reaching 10 Gbps needs a higher symbol rate, a multi-carrier / multi-channel configuration, or
dual polarization. This is a link-design question for the payload team.

## Why it does not affect RFC

For RFC/RFI the Ka transmit spectrum is represented as a flat 1.5 GHz occupied band. A narrower
carrier set inside the allocation would only reduce the spectral overlap with a victim receiver,
so the full-allocation baseline is the conservative bound. If a carrier plan is later fixed
(centre frequencies, symbol rates, roll-off), replace `bw_mhz` / add a `TabulatedSpectrum`; no code
change is needed.
