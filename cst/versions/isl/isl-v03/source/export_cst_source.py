"""Export genuine complex CST farfield source with vendor-macro syntax."""
import argparse,json
from pathlib import Path
from cst_com_common import connect_cst,method,get_active_project
from verify_sband_results import tree_paths

def export(p,destination,frequency,label='RHCP_INTENDED'):
    paths=tree_paths(p)
    matches=[item for item in paths if f'f={frequency:g})' in item and label in item]
    if len(matches)!=1:raise ValueError(f'Expected one coherent source monitor: {matches}')
    destination=Path(destination).resolve();destination.parent.mkdir(parents=True,exist_ok=True)
    if destination.exists():raise FileExistsError('Refusing source overwrite')
    method(p,'SelectTreeItem',matches[0])
    # Installed Export to EMIT^+MWS.mcr:253 uses this exact FarfieldPlot method.
    method(method(p,'FarfieldPlot'),'ASCIIExportAsBroadbandSource',str(destination))
    if not destination.exists() or destination.stat().st_size<1000:
        raise RuntimeError('No usable native farfield source exported')
    destination.with_suffix('.provenance.json').write_text(json.dumps({
        'producer':'ACTUAL_CST_COMPLEX_FARFIELD','monitor':matches[0],
        'api_evidence':'CST 2026 Library/Macros/Results/- Import and Export/Export to EMIT^+MWS.mcr:253',
        'normalization':'Preserve native file power metadata; normalize to accepted/radiated power when importing. This is not absolute conducted-power transfer.',
        'screening_envelope_clipped':False,'unknown_regions':'Raw physical source is not conservatively clipped; use separate conservative scalar screening envelopes.'},indent=2))
    return destination

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('project');parser.add_argument('destination');parser.add_argument('--frequency',type=float,required=True);a=parser.parse_args()
    app=connect_cst(False);p=method(app,'OpenFile',str(Path(a.project).resolve()))
    if p is None:p=get_active_project(app)
    print(export(p,a.destination,a.frequency),flush=True)
