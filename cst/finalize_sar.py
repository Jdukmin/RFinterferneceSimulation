"""SAR example exports: CST leaf native source + analytic array example cuts (NON-CST array stage)."""
import argparse,csv,json,math
from pathlib import Path
import numpy as np
from cst_com_common import connect_cst,get_active_project,method
from cst_com import ROOT
from export_cst_source import export as export_source
from eval_sar_leaf import af_db,NX,NY,taylor,D
from generate_sar_leaf import MONITORS

BACK_DB=40.0;FLOOR_DBI=-10.0

def main():
    a=argparse.ArgumentParser();a.add_argument('label');args=a.parse_args()
    res=ROOT/'results'/args.label;rep=json.loads((res/'validation.json').read_text())
    if rep['status']!='SAR_LEAF_PASS':raise SystemExit('leaf not passed')
    dest=ROOT/'exports'/'sar'
    if dest.exists():raise FileExistsError(dest)
    (dest/'array_example').mkdir(parents=True)
    for f in MONITORS:
        leaf={int(r['theta']):r for r in csv.DictReader((res/f'leaf_f{f:g}.csv').open())}
        g0=rep[f'f{f:g}']['array_example']['gain_aperture_dbi'];tag=f'{f:g}'.replace('.','p')
        for plane,N in [('XZ',NX),('YZ',NY)]:
            col=f'{plane}_co_dbi';e0=float(leaf[0][col])
            for name,grid in [('1deg',np.arange(360)),('fine_0p01deg_0to20',np.round(np.arange(0,20.0001,0.01),2))]:
                th=np.minimum(grid,360-grid) if name=='1deg' else grid
                ang=np.where(grid<=180,grid,grid-360) if name=='1deg' else grid
                e=np.interp(np.abs(ang),np.arange(181),[float(leaf[t][col]) for t in range(181)])-e0
                af,_=af_db(np.abs(ang),N,f)
                gain=g0+af+e
                if name=='1deg':
                    # SAR-A7: back hemisphere not modelled (isolated-leaf F/B x coherent AF is an
                    # artefact of the small leaf ground); front far-sidelobe floor for screening.
                    gain=np.where(np.abs(ang)>90,g0-BACK_DB,np.maximum(gain,FLOOR_DBI))
                with (dest/'array_example'/f'SAR_example_f{tag}_{plane}_{name}.csv').open('w',newline='') as st:
                    w=csv.writer(st);w.writerow(['theta','gain']);w.writerows(zip(grid,np.round(gain,4)))
    app=connect_cst(False);p=method(app,'OpenFile',str(ROOT/'projects'/f'{args.label}.cst'))
    if p is None:p=get_active_project(app)
    src=export_source(p,dest/'sar_leaf_broadband.ffs',MONITORS[1],label='LEAF_DIFF')
    (dest/'sar_final_validation.json').write_text(json.dumps({'selected_leaf':args.label,'leaf_validation':rep,
        'leaf_native_source':str(src),'array_example':{'layout':f'{NX} x {NY}, {D} mm, Taylor -25 dB nbar 4',
        'gain':'aperture 4 pi A/lambda^2 x taper efficiency','pattern':'leaf cut x array factor; coupling neglected',
        'stage':'NON_CST_ANALYTIC','note':'Owner: SAR is an example; beamwidth is an array property, not a leaf gate. 1 deg grid cannot resolve a 1 deg beam; use fine_0p01deg files for the main beam.'},
        'screening_1deg_rule':'front |theta|<=90: max(model, -10 dBi ASSUMED floor); back: peak-40 dB ASSUMED (large continuous ground panel); fine_0p01deg files are raw model',
        'mesh_validation':'DISABLED_BY_USER'},indent=2))
    print(dest)

if __name__=='__main__':main()
