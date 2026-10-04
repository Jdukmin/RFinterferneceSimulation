# GPS L2 fixed-geometry CST response

Owner requested the existing GNSS antenna shape be retained and calculated at
GPS L2 rather than treating the 1207 MHz datasheet plot as genuine L2 data.
These cuts are from the unchanged `LBAND_GNSS_FINAL_COMPROMISE` surrogate at
**1227.60 MHz**, four 50-ohm ports with phases 0/-90/-180/-270 degrees.

`GPS_L2_CST_1227p6_XZ.csv` and `_YZ.csv`: `theta,gain`, 360 samples 0–359
degrees, dBi, source boresight +Z, **accepted-power intended RHCP gain**.
They are simulated independent cuts, not measured or installed patterns.
The active `GPS_L2` binding uses these files; the original 1207 MHz proxy
files remain unchanged and available as `GPS_L2_PROXY_1207`.

Actual common-band run `RFC_L_LOW_FREE`: 65,000 cells, four successful port
excitations, 60.062 s. The same frozen numeric geometry was used; the mesh
uses 6 steps/wavelength and no mesh convergence is claimed. At L2 center,
accepted power fraction is 0.52885 and minimum active return loss is 3.268
dB (matching diagnostic only). `provenance.json` records full source data.

The 1217.37–1237.83 MHz analysis window comes from the existing **assumed
20.46 MHz receiver filter width**, not a manufacturer-certified antenna
passband. Center-only baseline cuts are reused within that window by the
existing baseline importer. Frequency-dependent low/center/high responses
are separately available in `data/antenna_port_response_cst/L/L2/`.

This is a surrogate calculation at the genuine GPS L2 carrier; it does not
establish the actual commercial antenna's L2 measured performance.
