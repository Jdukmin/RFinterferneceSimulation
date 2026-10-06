"""Move the observed upper resonance to L1, retaining L2/L5 matching."""
import json
import numpy as np
from tune_geometry import screen, OUT

BANDS = {'L1': (1.563, 1.588), 'L2': (1.21737, 1.23783),
         'L5': (1.164, 1.189)}
CANDIDATES = [
    (135, 94, 6, 45, 12), (135, 92, 6, 45, 12),
    (135, 96, 6, 45, 12), (135, 94, 6, 48, 12),
    (135, 92, 6, 48, 12), (135, 94, 4, 45, 12),
    (135, 96, 4, 45, 12), (130, 94, 6, 45, 12),
]


def band_metrics(f, s):
    a = np.exp(-1j * np.arange(4) * np.pi / 2)
    eta = 1 - np.sum(abs(s @ a) ** 2, axis=1) / 4
    values = {}
    for name, (lo, hi) in BANDS.items():
        grid = np.unique(np.r_[lo, f[(f > lo) & (f < hi)], hi])
        # Complex S interpolation, including exact band boundaries.
        matrices = np.empty((len(grid), 4, 4), dtype=complex)
        for i in range(4):
            for j in range(4):
                matrices[:, i, j] = np.interp(grid, f, s[:, i, j].real) + 1j * np.interp(grid, f, s[:, i, j].imag)
        power = 1 - np.sum(abs(matrices @ a) ** 2, axis=1) / 4
        index = np.argmin(power)
        values[name] = dict(minimum_fraction=float(power[index]),
                           worst_frequency_ghz=float(grid[index]),
                           band_ghz=[lo, hi])
    return values


def main():
    reports = []
    for index, values in enumerate(CANDIDATES, 22):
        report = screen(index, values)
        with np.load(OUT / report['case'] / 's_matrix_symmetry_screen.npz') as data:
            bands = band_metrics(data['frequency_ghz'], data['s'])
        report['band_minima'] = bands
        report['minimum_band_fraction'] = min(x['minimum_fraction'] for x in bands.values())
        reports.append(report)
        (OUT / 'refined_screening.json').write_text(json.dumps(reports, indent=2))
        print('BAND_MINIMUM', report['case'], bands, flush=True)
        if report['minimum_band_fraction'] >= .68:
            break
    best = max(reports, key=lambda r: r['minimum_band_fraction'])
    (OUT / 'best_candidate.json').write_text(json.dumps(best, indent=2))
    print('BEST', json.dumps(best), flush=True)


if __name__ == '__main__':
    main()
