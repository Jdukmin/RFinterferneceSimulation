# Ka-band DLS antenna pattern (1 deg)

## Source / design basis

This dataset represents a MetOp-SG / KARMA-7 FG-like Ka-band downlink reflector antenna for RFI screening.

Public hardware basis:
- Beyond Gravity MetOp-SG K-band all-metal reflector antenna
- Reflector diameter: approximately 0.22 m
- Frequency range: 25.5-27.0 GHz
- Circular polarization (RHCP or LHCP)
- Boresight gain: 32.6 dBi @ 25.5 GHz to 33.3 dBi @ 27 GHz
- Edge-of-coverage gain:
  - +/-0.5 deg: 32.3 to 33.0 dBi
  - +/-0.75 deg: 32.0 to 32.6 dBi
  - +/-1.0 deg: 31.6 to 31.2 dBi
- Cross-polarization discrimination: >29 dB within +/-1.0 deg
- Kongsberg KARMA-7 FG uses a 22 cm Ka-band antenna and was selected for the MetOp-SG Ka-band downlink.

Representative averages used for the main-beam model:
- 0 deg: 32.95 dBi
- +/-0.5 deg: 32.65 dBi
- +/-0.75 deg: 32.30 dBi
- +/-1.0 deg: 31.40 dBi

Additional project constraints:
- 3 dB beamwidth: approximately 3 deg total
- Managed beamwidth: 0.9 deg total (+/-0.45 deg)
- Gain within managed beam: >=31 dBi

## 1-degree generation method

The simulation input requested here is strictly 1-degree spaced.

Because the source contains sub-degree main-beam points while the CSV grid is 1 degree:
- 0 deg and 1 deg public/representative anchors are preserved.
- The 2 deg node is set to 28.50 dBi so linear interpolation at 1.5 deg gives approximately 29.95 dBi, preserving the specified ~3 dB beamwidth relative to the 32.95 dBi boresight.
- Linear interpolation between 0 deg and 1 deg still keeps the full +/-0.45 deg managed region above 31 dBi.
- Exact +/-0.5 deg and +/-0.75 deg measured/representative values cannot simultaneously be reproduced by a strict 1-degree table; the simulator interpolation is therefore slightly conservative in that sub-degree region.

## Sidelobe / backlobe approximation

Detailed measured KARMA-7 FG sidelobe data was not found in the public sources reviewed.

Therefore:
- Main beam is anchored to MetOp-SG/KARMA-7 performance.
- First-sidelobe region is conservatively approximated around ~15 dBi (~18 dB below boresight).
- Far sidelobes and backlobe use a generic smooth reflector-envelope approximation.
- These regions are model assumptions for RFI screening, not manufacturer-certified measurements.

## CSV schema

```text
theta,gain
0,32.950
1,31.400
2,28.500
...
```

- theta: deg, canonical 0 <= theta < 360
- gain: dBi
- 0-180 deg is mirrored to 181-359 deg.
- XZ and YZ are identical under an axisymmetric reflector approximation.
- Compatible with `rfscreen.patterndata.CsvPatternImporter`.

## Files

- KARMA7_FG_KaBand_XZ.csv
- KARMA7_FG_KaBand_YZ.csv

## Public references

Beyond Gravity:
https://www.beyondgravity.com/de/node/131

Beyond Gravity K-band antenna datasheet:
https://www.beyondgravity.com/sites/default/files/media_document/2023-11/K-band-Link-Antennas.pdf

Kongsberg KARMA-7 FG:
https://www.kongsberg.com/what-we-do/space/space-mechanisms/apm/karma-7-fg/

## Usage

Datasheet/specification-derived approximate RFI screening pattern.
Do not treat the generic sidelobe/backlobe section as measured KARMA-7 flight data.
