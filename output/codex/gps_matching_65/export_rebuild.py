"""Classic reconstruction macro for the independently validated GPS candidate."""
import json
import sys
from types import SimpleNamespace
from tune_geometry import ROOT, OUT, PHASES
sys.path.insert(0, str(ROOT / 'cst/closed_network'))
from prepare_2024_rebuild import Recorder, native, vba_text, digest, port_records
from cst_sband_helix_com import configure_frequency, configure_boundaries
from cst_com import monitor


def main():
    folder = OUT / 'validated_candidate'
    validation = json.loads((folder / 'validation.json').read_text())
    assert validation['status'] == 'MEETS_65_PERCENT'
    spec = json.loads((folder / 'spec.json').read_text())
    values = {k: d['value'] for k, d in spec['dimensions'].items()}
    recorder = Recorder()
    configure_frequency(recorder, SimpleNamespace(fmin=1.164, fmax=1.588))
    configure_boundaries(recorder)
    recorder.AddToHistory('Lowest-monitor PML reference',
                          'Boundary.MinimumDistanceReferenceFrequencyType "CenterNMonitors"')
    recorder.AddToHistory('Steady-state accuracy', 'Solver.SteadyStateLimit "-40"')
    recorder.blocks += native('GPS', values)
    for frequency in spec['frequency']['initial_monitors_ghz']:
        monitor(recorder, frequency)
    recorder.AddToHistory('Mesh resource configuration',
        'With Mesh\n .MergeThinPECLayerFixpoints "True"\n .RatioLimit "5"\nEnd With\n'
        'With MeshSettings\n .SetMeshType "Hex"\n .Set "StepsPerWaveNear", "8"\n'
        ' .Set "StepsPerWaveFar", "8"\n .Set "StepsPerBoxNear", "8"\n'
        ' .Set "StepsPerBoxFar", "8"\nEnd With')
    recorder.AddToHistory('Structure view', 'ResetViewToStructure\nPlot.ZoomToStructure')
    text = vba_text('GPS_TRIBAND_MATCH65', recorder.blocks).rstrip() + '\n'
    # CombineResults is deliberately deferred until four-port solver results exist.
    assert 'Solver.Start' not in text and 'SetPortModeValues' not in text
    (folder / 'build_2024.vba').write_text(text, encoding='utf-8')
    (folder / 'source_geometry.json').write_text(json.dumps(dict(
        parameters_mm=values, classic_history=recorder.blocks,
        geometry_hash=digest(native('GPS', values)),
        ports=port_records(native('GPS', values)), phases_deg=PHASES,
        installed=False, coordinate_frame='LOCAL_PLUS_Z',
        solver_auto_run=False, cst2024_execution='NOT_PERFORMED',
    ), indent=2))
    (folder / 'README.md').write_text('''# GPS L1/L2/L5 matching candidate

The original accepted antenna and all 22 closed-network projects are unchanged.
Local CST 2026 all-port results are in `validation.json` and `s_matrix.npz`.
This engineering surrogate is not a measured product antenna.

For CST 2024: create an empty Microwave Studio project, run `build_2024.vba`,
check all four 50-ohm discrete ports, nine monitors and mesh, then save as
`GPS_TRIBAND_MATCH65_CST2024.cst`. The build macro does not start a solver.
Actual CST 2024 execution has not been performed on this development PC.

Run all four ports. After solving, combine equal amplitudes with phases
`0, -90, -180, -270` degrees. Calculate acceptance from the full complex
four-port S-matrix, not S11 alone. Do not change the 50-ohm reference to
obtain apparent matching. Export RAW realized gain and complex fields
without clipping. Existing local RAW cuts are separate candidate data;
they have not replaced the RFI baseline or installed patterns.
''', encoding='utf-8')
    print('PASS: classic rebuild macro; 4 unchanged-reference ports; no automatic solver or premature CombineResults.')


if __name__ == '__main__':
    main()
