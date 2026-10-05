"""Validate RAW gain; create separate import views without changing originals."""
import csv,json,math,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
rows=list(csv.DictReader((ROOT/'docs/closed_network_cst_project_inventory.csv').open(encoding='utf-8')));registry=[]
for r in rows:
 dataset=Path(r['expected_output_directory']);folder=ROOT/dataset;provenance=folder/'provenance.json'
 if not provenance.is_file():continue
 meta=json.loads(provenance.read_text());assert meta['status']=='SOLVED_ACCEPTED' and meta['gain_quantity']=='RealizedGain' and meta['gain_unit']=='dBi' and meta['convergence_accepted']
 assert meta['project_file']==r['project_file'] and meta['frame']=='CST_LOCAL_PRESERVED'
 assert sorted(float(m['frequency_ghz']) for m in meta['monitors'])==sorted(float(r[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz'])
 assert all(m['normalization_reliable'] for m in meta['monitors'])
 imported=folder/'registered';imported.mkdir(exist_ok=True)
 files=[]
 for f in [float(r[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz']]:
  for plane in ['XZ','YZ']:
   name=f'f{f:.6f}_{plane}.csv';raw=list(csv.DictReader((folder/name).open(encoding='utf-8')))
   assert len(raw)==360 and [float(v['theta']) for v in raw]==list(range(360)),name
   assert all(math.isfinite(float(v['realized_gain_dbi'])) for v in raw),name
   target=imported/name
   with target.open('w',newline='',encoding='utf-8') as stream:
    w=csv.writer(stream);w.writerow(['theta','gain']);w.writerows((v['theta'],v['realized_gain_dbi']) for v in raw)
   files.append(dict(path=str((dataset/'registered'/name).as_posix()),raw_sha256=hashlib.sha256((folder/name).read_bytes()).hexdigest()))
 registry.append(dict(dataset_id=Path(r['project_file']).stem.replace('RFC_',''),configuration_id='CN_'+Path(r['project_file']).stem.replace('RFC_',''),pattern_class='InstalledPattern' if r['configuration']=='INSTALLED' else 'FreeSpacePattern',
  installation_id=r['installation_identity'],directory=dataset.as_posix(),frequencies_ghz=[float(r[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz']],files=files,frame='CST_LOCAL_PRESERVED',gain_quantity='RealizedGain'))
(ROOT/'data/closed_network_patterns/registry.json').write_text(json.dumps(registry,indent=2)+'\n',encoding='utf-8')
print('Registered accepted datasets:',len(registry))
