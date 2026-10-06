"""Reference extraction and classic command replay in CST2026 ONLY; no solve.

This does not establish actual CST2024 execution or convergence. Source projects
are opened as temporary copies; accepted originals are never written.
"""
import argparse, json, shutil, sys, tempfile, time
from pathlib import Path
import numpy as np
import pythoncom, win32com.client
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from cst_com_common import connect_cst, method, get_active_project
from fixed_body_geometry import ROOT, sha, write_json
from prepare_2024_rebuild import OUT

def box(solid,name):
    args=[win32com.client.VARIANT(pythoncom.VT_BYREF|pythoncom.VT_R8,0.) for _ in range(6)]
    method(solid,'GetLooseBoundingBoxOfShape',name,*args)
    return [float(x.value) for x in args]

def snapshot(p,n):
    solid=method(p,'Solid');names=[method(solid,'GetNameOfShapeFromIndex',i) for i in range(int(method(solid,'GetNumberOfShapes')))]
    records={};bbox=[]
    for name in names:
        b=box(solid,name);bbox.append(b)
        if name.startswith('RECONSTRUCTION:'):
            records[name]=dict(volume_mm3=float(method(solid,'GetVolume',name)),bbox_mm=b,material=method(solid,'GetMaterialNameForShape',name))
    a=np.array(bbox);b=[float(a[:,i].min() if i%2==0 else a[:,i].max()) for i in range(6)]
    obj=method(p,'DiscretePort');ports=[]
    for no in range(1,n+1):
        args=[win32com.client.VARIANT(pythoncom.VT_BYREF|pythoncom.VT_R8,0.) for _ in range(6)]
        assert method(obj,'GetCoordinates',no,*args)
        ports.append(dict(number=no,endpoints_mm=[float(v.value) for v in args],impedance_ohm=float(method(method(p,'Port'),'GetLineImpedance',no,1))))
    m=method(p,'Monitor');monitors=[method(m,'GetMonitorNameFromIndex',i) for i in range(int(method(m,'GetNumberOfMonitors')))]
    return dict(geometry_object_count=len(names),component_count=len({x.split(':')[0] for x in names}),material_count=len({method(solid,'GetMaterialNameForShape',x) for x in names}),
        port_count=int(method(method(p,'Port'),'StartPortNumberIteration')),monitor_count=len(monitors),monitor_names=monitors,bounding_box_mm=b,
        bounding_box_definition='Union of CST Solid.GetLooseBoundingBoxOfShape; conservative native CAD extents, not fitted dimensions.',base_antenna_solids=records,ports=ports,
        spacecraft_panel_count=len([x for x in names if x.startswith('FULL_SPACECRAFT:PANEL_')]),object_names=names)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--case');args=parser.parse_args()
    app=connect_cst(False);root=Path(tempfile.mkdtemp(prefix='cst2026_rebuild_validation_'));reports=[]
    manifests=sorted(OUT.glob('*/*/build_manifest.json'))
    if args.case:manifests=[x for x in manifests if x.parent.name==args.case]
    for mf in manifests:
        folder=mf.parent;manifest=json.loads(mf.read_text());ref_path=folder/'validation_reference.json';ref=json.loads(ref_path.read_text());geom=json.loads((folder/'source_geometry.json').read_text())
        src=ROOT/manifest['source_project'];before=sha(src);copy=root/('source_'+src.name);shutil.copy2(src,copy)
        p=method(app,'OpenFile',str(copy));p=p or get_active_project(app)
        expected=snapshot(p,manifest['port_count']);method(p,'Quit');assert sha(src)==before
        p=method(app,'NewMWS');assert int(method(method(p,'Solid'),'GetNumberOfShapes'))==0
        start=time.time()
        try:
            for block in geom['project_history']:
                result=method(p,'AddToHistory',block['name'],block['code'])
                assert result is not False,(manifest['case_id'],block['name'])
            actual=snapshot(p,manifest['port_count'])
            for key in ['geometry_object_count','component_count','material_count','port_count','monitor_count','spacecraft_panel_count']:
                assert actual[key]==expected[key]==ref[key],(manifest['case_id'],key,actual[key],expected[key],ref[key])
            assert set(actual['object_names'])==set(expected['object_names'])
            assert sorted(actual['monitor_names'])==sorted(expected['monitor_names'])
            np.testing.assert_allclose(actual['bounding_box_mm'],expected['bounding_box_mm'],atol=.02,rtol=0)
            maxvol=0.;maxbbox=0.
            for name,s in expected['base_antenna_solids'].items():
                t=actual['base_antenna_solids'][name];err=abs(t['volume_mm3']-s['volume_mm3'])/max(1,abs(s['volume_mm3']));maxvol=max(maxvol,err)
                assert err<1e-5,(name,err);assert t['material']==s['material'];np.testing.assert_allclose(t['bbox_mm'],s['bbox_mm'],atol=.02,rtol=0)
                maxbbox=max(maxbbox,float(np.max(abs(np.array(t['bbox_mm'])-s['bbox_mm']))))
            for a,b,g in zip(actual['ports'],expected['ports'],geom['ports']):
                np.testing.assert_allclose(a['endpoints_mm'],b['endpoints_mm'],atol=1e-7,rtol=0)
                np.testing.assert_allclose(a['endpoints_mm'],g['point1_mm']+g['point2_mm'],atol=1e-7,rtol=0)
                assert a['impedance_ohm']==b['impedance_ohm']==50
            ref.update(expected)
            ref.update(bounding_box_status='EXTRACTED_FROM_CST2026_SOURCE_TEMP_COPY',classic_history_replay_cst2026='PASS',actual_cst2024_execution=False,solver_started=False,
                replay_comparison=dict(max_solid_volume_relative_error=maxvol,max_base_solid_bbox_difference_mm=maxbbox,volume_relative_tolerance=1e-5,bbox_absolute_tolerance_mm=.02,port_endpoint_tolerance_mm=1e-7,elapsed_seconds=round(time.time()-start,2)))
            write_json(ref_path,ref);manifest['expected_bbox_mm']=ref['bounding_box_mm'];manifest['classic_history_replay_cst2026']='PASS';write_json(mf,manifest)
            reports.append(dict(case_id=manifest['case_id'],status='PASS_CST2026_CLASSIC_HISTORY_REPLAY',source_sha256=before,objects=actual['geometry_object_count'],ports=actual['port_count'],monitors=actual['monitor_count'],bbox_mm=actual['bounding_box_mm'],max_volume_relative_error=maxvol,actual_cst2024_execution=False,solver_started=False))
            print(manifest['case_id'],'PASS',len(actual['object_names']),'objects',round(time.time()-start,1),'s',flush=True)
        finally:
            method(p,'SaveAs',str(root/('replayed_'+src.name)),True)
            method(p,'Quit')
    if not args.case:
        assert len(reports)==22
        write_json(OUT/'cst2026_replay_validation.json',dict(status='PASS',projects=22,actual_execution_version=2026,actual_cst2024_execution=False,solver_started=False,source_projects_unchanged=True,records=reports))

if __name__=='__main__':main()
