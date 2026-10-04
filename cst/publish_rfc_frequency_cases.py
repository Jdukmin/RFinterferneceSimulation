"""Publish completed fixed-port response cuts separately from frozen originals."""
import csv,json
from pathlib import Path
from run_rfc_frequency_cases import ROOT,OUT,BANDS,USAGE_ROLES

DEST=ROOT.parent/'data/antenna_port_response_cst'

def publish():
    cases=[];exportmap={}
    statuspaths=sorted(OUT.glob('*/status.json'),key=lambda p:
        ('_LOW_' in p.parent.name or '_HIGH_' in p.parent.name,p.parent.name))
    for statuspath in statuspaths:
        record=json.loads(statuspath.read_text())
        entry={k:record.get(k) for k in ['case','family','band','status','installation','solver_runtime_s']}
        entry['mesh_cells']=record.get('actual_solver_log',{}).get('mesh_cells',[])
        if not entry['mesh_cells'] and record.get('mesh_attempts'):
            entry['preflight_cells']=record['mesh_attempts'][-1]['mesh_cells']
        cases.append(entry)
        if record['status']!='SOLVED':continue
        if record['installation']:continue # Installed correction needs matched free + convergence.
        for freq in record['monitor_frequencies_ghz']:
            targetbands=[record['band']] if record['band'] not in ['LOW','HIGH'] else [
                name for name,values in BANDS.items() if any(abs(freq-f)<1e-9 for f in values)]
            for plane in ['XZ','YZ']:
                key=f'f{freq:g}_{plane}'
                diagnostics=record['patterns'][key]
                with (statuspath.parent/f'{key}.csv').open() as stream:
                    rows=list(csv.DictReader(stream))
                if [int(row['theta']) for row in rows]!=list(range(360)):
                    raise ValueError(f'Incomplete angular cut: {key}')
                quantities={'RealizedGain':'realized_gain_dbi'}
                if diagnostics['normalization_reliable']:
                    quantities.update(Gain='gain_dbi',IntendedCPGain='dominant_cp_gain_dbi')
                for quantity,column in quantities.items():
                    for targetband in targetbands:
                        out=DEST/record['family']/targetband;out.mkdir(parents=True,exist_ok=True)
                        path=out/f'f{freq:g}_{quantity}_{plane}.csv'
                        with path.open('w',newline='') as stream:
                            writer=csv.writer(stream);writer.writerow(['theta','gain'])
                            writer.writerows((row['theta'],row[column]) for row in rows)
                        relative=path.relative_to(ROOT.parent).as_posix()
                        exportmap[relative]={'path':relative,
                            'rf_usage_roles':USAGE_ROLES[record['family']],
                            'family':record['family'],'band':targetband,'frequency_hz':freq*1e9,
                            'plane':plane,'boresight':'+Z','quantity':quantity,
                            'free_space':True,'provenance':'CST_FIXED_GEOMETRY_PORT_RESPONSE',
                            'normalization_reliable':diagnostics['normalization_reliable'],
                            'accepted_power_fraction':diagnostics['accepted_power_fraction'],
                            'source_case':record['case']}
    exports=list(exportmap.values())
    manifest={'cases':cases,'cuts':exports,'bands_ghz':BANDS,
        'rf_usage_roles':USAGE_ROLES,'excluded_role_jobs':['KA_RX','L_TX'],
        'scope':'S/L/ISL fixed surrogate responses at interferer frequencies',
        'excluded':'Full Ka out-of-band reflector response; SAR source pattern; no fabricated installed results',
        'source_limitations':'Not manufacturer-certified antenna response; no mesh/frequency convergence claim',
        'sba_variants':'One frozen S CST geometry shared; SBA1/SBA4 reference distinction preserved separately',
        'angular_limitations':'Two actual independent cuts; no complete 3D installed pattern inferred',
        'normalization':'Gain accepted-power total; IntendedCPGain accepted-power intended circular sense; RealizedGain incident-power total'}
    DEST.mkdir(parents=True,exist_ok=True)
    (DEST/'provenance.json').write_text(json.dumps(manifest,indent=2))
    with (OUT/'case_summary.csv').open('w',newline='') as stream:
        fields=['case','family','band','status','installation','solver_runtime_s','mesh_cells','preflight_cells']
        writer=csv.DictWriter(stream,fieldnames=fields);writer.writeheader();writer.writerows(cases)
    print(json.dumps({'cases':len(cases),'solved':sum(c['status']=='SOLVED' for c in cases),
        'mesh_limited':sum(c['status']=='MESH_LIMIT' for c in cases),'published_cuts':len(exports)}),flush=True)
    return manifest

if __name__=='__main__':publish()
