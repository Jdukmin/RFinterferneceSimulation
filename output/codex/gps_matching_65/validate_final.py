"""All-port verification and separate RAW pattern export for a GPS candidate."""
import csv
import hashlib
import json
import re
import sys
import numpy as np
from tune_geometry import ROOT, OUT, PHASES, TARGETS, spec_for
from refine_geometry import band_metrics, BANDS
from generate_lband_gnss import build
from cst_com import save
from cst_com_common import method
from cst_results import s_matrix, active_reflection, farfield_complex
from verify_sband_results import tree_paths


def main():
    best = json.loads((OUT / 'best_candidate.json').read_text())
    spec = spec_for(best['dimensions_mm'])
    monitors = sorted(set(TARGETS + [x for limits in BANDS.values() for x in limits]))
    spec['frequency']['initial_monitors_ghz'] = monitors
    folder = OUT / 'validated_candidate'
    folder.mkdir(parents=True, exist_ok=True)
    project_path = folder / 'GPS_TRIBAND_MATCH65.cst'
    (folder / 'spec.json').write_text(json.dumps(spec, indent=2))
    app, project = build(spec, project_path, solve=True)
    f, s = s_matrix(project)
    active = active_reflection(s, PHASES)
    np.savez(folder / 's_matrix.npz', frequency_ghz=f, s=s,
             phases_deg=PHASES, active_gamma=active)
    eta = 1 - np.mean(abs(active) ** 2, axis=1)
    nominal = {str(x): float(np.interp(x, f, eta)) for x in TARGETS}
    bands = band_metrics(f, s)
    baseline_path = ROOT / 'cst/results/LBAND_GNSS_FINAL_COMPROMISE/s_matrix.npz'
    with np.load(baseline_path) as old:
        old_eta = 1 - np.mean(abs(active_reflection(old['s'], PHASES)) ** 2, axis=1)
        baseline = {str(x): float(np.interp(x, old['frequency_ghz'], old_eta)) for x in TARGETS}
    mask = np.zeros(len(f), dtype=bool)
    for lo, hi in BANDS.values():
        mask |= (f >= lo) & (f <= hi)
    passivity_excess = float(np.max(np.linalg.svd(s[mask], compute_uv=False)[:, 0] ** 2 - 1))
    report = dict(
        status='MEETS_65_PERCENT' if all(v['minimum_fraction'] >= .65 for v in bands.values()) else 'TARGET_NOT_MET',
        candidate=best['case'], parameters_mm={k: v['value'] for k, v in spec['dimensions'].items()},
        nominal_fraction=nominal, baseline_nominal_fraction=baseline, band_minima=bands,
        phases_deg=PHASES, port_reference_impedance_ohm=50,
        full_s_matrix=True, symmetry_reconstruction_used_for_final=False,
        passivity_excess_over_evaluation_samples=passivity_excess,
        baseline_sha256=hashlib.sha256(baseline_path.read_bytes()).hexdigest(),
        mesh_convergence='NOT_VERIFIED; existing 8-cells/wavelength resource setting',
        solver='CST 2026 local Learning Edition; Time Domain; all four ports; -40 dB termination',
        actual_product_matching='NOT_MEASURED; engineering surrogate',
        cst2024_execution='NOT_PERFORMED',
    )
    log_path = project_path.with_suffix('') / 'Result/Model.log'
    log = log_path.read_text(errors='replace')
    report['mesh_cell_counts'] = [int(x) for x in re.findall(r'Number of mesh cells:\s*(\d+)', log)]
    report['solver_error_present'] = '*** Error ***' in log
    (folder / 'validation.json').write_text(json.dumps(report, indent=2))
    with (folder / 'matching_sweep.csv').open('w', newline='') as stream:
        writer = csv.writer(stream)
        writer.writerow(['frequency_ghz', 'accepted_power_fraction', 'mismatch_loss_db', 'aggregate_return_loss_db'])
        for frequency, fraction in zip(f, eta):
            writer.writerow([frequency, fraction, -10*np.log10(fraction) if fraction>0 else '',
                             -10*np.log10(1-fraction) if fraction<1 else ''])
    combine = method(project, 'CombineResults')
    method(combine, 'Reset')
    method(combine, 'SetMonitorType', 'frequency')
    method(combine, 'FarfieldsOnly', True)
    method(combine, 'EnableAutomaticLabeling', False)
    method(combine, 'SetLabel', 'MATCH65_CP')
    for i, phase in enumerate(PHASES):
        method(combine, 'SetPortModeValues', i+1, 1, 1.0, phase)
    method(combine, 'Run')
    paths = tree_paths(project)
    for frequency in TARGETS:
        matches = [p for p in paths if f'f={frequency:g})' in p and 'MATCH65_CP' in p]
        if len(matches) != 1:
            raise ValueError(f'Combined monitor missing: {frequency}')
        rows = farfield_complex(project, matches[0])
        for plane in ['XZ', 'YZ']:
            selected = [r for r in rows if r['plane'] == plane]
            with (folder / f'f{frequency:g}_RAW_RealizedGain_{plane}.csv').open('w', newline='') as stream:
                writer = csv.DictWriter(stream, fieldnames=list(selected[0]))
                writer.writeheader()
                writer.writerows(selected)
    save(project, project_path)
    print(json.dumps(report, indent=2), flush=True)
    if report['status'] != 'MEETS_65_PERCENT' or report['solver_error_present']:
        raise RuntimeError('Three-band requirement not met; retain as candidate only')


if __name__ == '__main__':
    main()
