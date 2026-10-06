"""Compare saved four-port S matrices; never invoke an EM solver."""
from pathlib import Path
import csv
import hashlib
import json
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
CASES = [
    ('GPS L1', 'LBAND_GNSS_FINAL_COMPROMISE', 1.57542),
    ('GPS L2 (S-matrix only)', 'LBAND_GNSS_FINAL_COMPROMISE', 1.22760),
    ('GPS L5', 'LBAND_GNSS_FINAL_COMPROMISE', 1.17645),
    ('SBA 2.25 GHz', 'SBAND_MATCHING_WIRE15', 2.25),
    ('SBA 2.06 GHz reference', 'SBAND_MATCHING_WIRE15', 2.06),
    ('ISL', 'ISL_C4_CUP_R14P7', 10.60),
    ('KAA feed only', 'KA_FEED_C_OEWG', 26.25),
]


def main():
    rows, provenance = [], {}
    for antenna, source, frequency in CASES:
        path = ROOT / 'cst/results' / source / 's_matrix.npz'
        with np.load(path) as data:
            f, s, phases = data['frequency_ghz'], data['s'], data['phases_deg']
            assert f.min() - 1e-6 <= frequency <= f.max() + 1e-6
            assert s.shape == (len(f), 4, 4)
            a = np.exp(1j * np.deg2rad(phases))
            # Existing active_gamma provides an independent stored-result check.
            calculated = (s @ a) / a
            np.testing.assert_allclose(calculated, data['active_gamma'], rtol=1e-9, atol=1e-9)
            matrix = np.array([
                [np.interp(frequency, f, s[:, i, j].real)
                 + 1j * np.interp(frequency, f, s[:, i, j].imag)
                 for j in range(4)] for i in range(4)
            ])
            outgoing = float(np.vdot(matrix @ a, matrix @ a).real / np.vdot(a, a).real)
            accepted = 1 - outgoing
            assert 0 < accepted <= 1
            singular_excess = float(np.linalg.svd(matrix, compute_uv=False)[0] ** 2 - 1)
            assert singular_excess < 1e-6
            sii = 20 * np.log10(np.abs(np.diag(matrix)))
            rows.append(dict(
                antenna=antenna, frequency_ghz=frequency, source_model=source,
                phases_deg='/'.join(str(int(x)) for x in phases),
                accepted_power_fraction=accepted, accepted_power_percent=100 * accepted,
                mismatch_loss_db=float(-10 * np.log10(accepted)),
                aggregate_active_return_loss_db=float(-10 * np.log10(outgoing)),
                s11_db=float(sii[0]), s22_db=float(sii[1]),
                s33_db=float(sii[2]), s44_db=float(sii[3]),
                passivity_excess=singular_excess,
                engineering_10db_reference='MET' if outgoing <= 0.1 else 'NOT_MET',
            ))
            provenance[source] = dict(
                input_file=path.relative_to(ROOT).as_posix(),
                sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                saved_frequency_range_ghz=[float(f.min()), float(f.max())],
                phases_deg=phases.tolist(),
            )
    with (OUT / 'nominal_band_matching_comparison.csv').open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    (OUT / 'nominal_band_matching_provenance.json').write_text(json.dumps(dict(
        inputs=provenance, solver_run=False,
        method='Linear interpolation of complex S; b=S*a; eta=1-(b^H*b)/(a^H*a)',
        checks='Stored active_gamma agreement, 4-port shape, frequency coverage, nominal passivity, power balance',
        scope='Existing original/free-space results only; no installed or closed-network results',
        limitations=[
            'GPS 1.207 GHz legacy proxy is not GPS L2; actual L2 evaluated at 1.22760 GHz from S only.',
            'ISL saved sweep ends at approximately 10.60 GHz; 10.60-10.65 GHz unverified.',
            'KAA results describe accepted feed only, not full reflector matching.',
            '10 dB aggregate return loss is a comparison reference, not an approved project requirement.',
        ],
    ), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('PASS: 7 comparisons; all four stored active_gamma arrays reproduced; no solver run.')
    for row in rows:
        print(row['antenna'], f"accepted={row['accepted_power_percent']:.3f}%",
              f"loss={row['mismatch_loss_db']:.3f} dB",
              f"aggregate_RL={row['aggregate_active_return_loss_db']:.3f} dB")


if __name__ == '__main__':
    main()
