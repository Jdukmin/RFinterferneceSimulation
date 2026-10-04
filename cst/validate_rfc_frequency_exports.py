"""Check published cut completeness, source values and normalization labels."""
import csv,json,math
from pathlib import Path
from run_rfc_frequency_cases import ROOT,OUT

def validate():
    root=ROOT.parent
    manifest=json.loads((root/'data/antenna_port_response_cst/provenance.json').read_text())
    seen=set()
    for cut in manifest['cuts']:
        identity=(cut['family'],cut['band'],cut['frequency_hz'],cut['plane'],cut['quantity'])
        if identity in seen:raise AssertionError(f'Duplicate cut {identity}')
        seen.add(identity)
        with (root/cut['path']).open() as stream:rows=list(csv.DictReader(stream))
        assert len(rows)==360 and [int(r['theta']) for r in rows]==list(range(360))
        assert all(math.isfinite(float(r['gain'])) for r in rows)
        status=json.loads((OUT/cut['source_case']/'status.json').read_text())
        assert status['status']=='SOLVED' and max(status['actual_solver_log']['mesh_cells'])<100000
        assert status['geometry_changed'] is False and status['installation'] is None
        freq=cut['frequency_hz']/1e9
        with (OUT/cut['source_case']/f"f{freq:g}_{cut['plane']}.csv").open() as stream:
            source=list(csv.DictReader(stream))
        column={'Gain':'gain_dbi','RealizedGain':'realized_gain_dbi',
                'IntendedCPGain':'dominant_cp_gain_dbi'}[cut['quantity']]
        assert all(float(a['gain'])==float(b[column]) for a,b in zip(rows,source))
        if cut['quantity']!='RealizedGain':assert cut['normalization_reliable'] is True
        if cut['normalization_reliable']:
            correction=-10*math.log10(cut['accepted_power_fraction'])
            for r in source:
                assert abs(float(r['gain_dbi'])-float(r['realized_gain_dbi'])-correction)<1e-10
                assert float(r['dominant_cp_gain_dbi'])<=float(r['gain_dbi'])+1e-9
    print(json.dumps({'validated_cuts':len(seen),'status':'PASS'}))

if __name__=='__main__':validate()
