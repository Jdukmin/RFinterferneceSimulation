"""Independent GPS geometry candidates, real CST solves, unchanged 50-ohm ports.

One-port screening assumes the exact fourfold geometry symmetry. A finalist
must be rerun with all four ports before claiming the three-band requirement.
"""
from pathlib import Path
import sys
import json
import csv
import numpy as np
import yaml

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'cst'))
from generate_lband_gnss import build
from cst_com import run, save
from cst_com_common import add_to_history, method
from cst_results import result, s_matrix, active_reflection

OUT = Path(__file__).resolve().parent
TARGETS = [1.17645, 1.22760, 1.57542]
PHASES = [0, -90, -180, -270]
# lower diameter, upper diameter, spacing, feed radius, driven height [mm]
CANDIDATES = [
    (140, 105, 6, 35, 12),
    (140, 105, 6, 45, 12),
    (140, 110, 6, 45, 12),
    (140, 100, 6, 45, 12),
    (135, 105, 6, 45, 12),
    (145, 105, 6, 45, 12),
    (140, 105, 3, 45, 12),
    (140, 105, 9, 45, 12),
    (105, 140, 6, 35, 12),
    (110, 140, 6, 40, 12),
    (140, 105, 6, 50, 8),
    (140, 105, 6, 45, 16),
]


def spec_for(values):
    spec = yaml.safe_load((ROOT / 'cst/specs/lband_gnss.yaml').read_text())
    names = ['lower_patch_diameter', 'upper_patch_diameter', 'patch_spacing',
             'feed_radius', 'patch_to_ground_height']
    for key, value in zip(names, values):
        spec['dimensions'][key]['value'] = value
        spec['dimensions'][key]['provenance'] = 'INDEPENDENT_CST_MATCHING_OPTIMIZATION'
        spec['dimensions'][key]['tag'] = 'CANDIDATE_GEOMETRY_PARAMETER'
    if len(values) >= 6:
        spec['dimensions']['feed_probe_radius']['value'] = values[5]
    spec['frequency']['initial_solve_ghz'] = [1.164, 1.588]
    spec['frequency']['initial_monitors_ghz'] = TARGETS
    spec['model_identity'] = 'GPS_THREE_BAND_MATCHING_INDEPENDENT_CANDIDATE'
    spec['status'] = 'ENGINEERING_CANDIDATE_NOT_MEASURED_PRODUCT'
    spec['analysis_policy']['matching'] = 'MINIMUM_65_PERCENT_AT_GPS_L1_L2_L5'
    return spec


def metrics(f, s):
    a = active_reflection(s, PHASES)
    eta = 1 - np.mean(abs(a) ** 2, axis=1)
    return {str(x): float(np.interp(x, f, eta)) for x in TARGETS}


def screen(index, values):
    case = f'v{index:02d}'
    out = OUT / case
    out.mkdir(parents=True, exist_ok=True)
    spec = spec_for(values)
    (out / 'spec.json').write_text(json.dumps(spec, indent=2))
    path = out / f'GPS_TRIBAND_{case.upper()}.cst'
    if (out / 'screen_summary.json').exists():
        return json.loads((out / 'screen_summary.json').read_text())
    app, project = build(spec, path, solve=False)
    add_to_history(project, 'One-port geometric symmetry candidate screening',
                   'Solver.StimulationPort "1"')
    save(project, path)
    run(project)
    save(project, path)
    cols = []
    for i in range(4):
        r = result(project, rf'1D Results\S-Parameters\S{i+1},1')
        f = np.array(method(r, 'GetArray', 'x'))
        cols.append(np.array(method(r, 'GetArray', 'yre'))
                    + 1j * np.array(method(r, 'GetArray', 'yim')))
    # Same upward port polarity, C4 rotation maps port numbers cyclically.
    s = np.stack([cols[(i-j) % 4] for i in range(4) for j in range(4)],
                 axis=1).reshape(-1, 4, 4)
    np.savez(out / 's_matrix_symmetry_screen.npz', frequency_ghz=f, s=s,
             phases_deg=PHASES, active_gamma=active_reflection(s, PHASES))
    fractions = metrics(f, s)
    report = dict(case=case, dimensions_mm=values, accepted_power_fraction=fractions,
                  minimum_fraction=min(fractions.values()),
                  status='ONE_PORT_C4_SYMMETRY_SCREEN_NOT_FINAL_VALIDATION',
                  project=str(path.relative_to(ROOT)))
    (out / 'screen_summary.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report), flush=True)
    method(project, 'Quit')
    return report


def main():
    reports = []
    for i, values in enumerate(CANDIDATES, 10):
        reports.append(screen(i, values))
        (OUT / 'candidate_screening.json').write_text(json.dumps(reports, indent=2))
        if reports[-1]['minimum_fraction'] >= .72:
            break
    print('BEST', json.dumps(max(reports, key=lambda r: r['minimum_fraction'])), flush=True)


if __name__ == '__main__':
    main()
