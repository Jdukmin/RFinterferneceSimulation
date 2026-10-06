"""Verify separately saved native CST2024 project and human geometry acceptance.

This checks provenance integrity; it cannot infer CST version from a filename.
The reviewer must record the actual About/version and geometry checks in CST2024.
"""
import hashlib,json
from pathlib import Path

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def verify_native_2024(root,package,native_project,validation_file):
 root=Path(root).resolve();package=(root/package).resolve();native=(root/native_project).resolve();validation=(root/validation_file).resolve()
 assert package.is_relative_to(root/'cst/projects/closed_network_2024_build') and native.is_relative_to(root/'cst/projects/closed_network_2024_native') and validation.is_relative_to(root)
 m=json.loads((package/'build_manifest.json').read_text());record=json.loads(validation.read_text())
 assert native.name==m['expected_native_filename'] and native.is_file()
 assert record['case_id']==m['case_id'] and record['actual_cst_version']==2024 and record['status']=='GEOMETRY_ACCEPTED_CST2024'
 assert record['native_project_file']==native.relative_to(root).as_posix() and record['native_project_sha256']==sha(native)
 assert record['source_geometry_hash']==m['source_geometry_hash'] and record['build_vba_sha256']==m['build_vba_sha256']==sha(package/'build_2024.vba')
 assert m['source_geometry_file_sha256']==sha(package/'source_geometry.json')
 assert record['reviewer'] and record['checked_at'] and record['about_version_text']
 required=['geometry','bbox','materials','ports','phase','reference_plane','monitors','boundaries','installation_frames','all_ssot_panels','no_crop','native_2024_save']
 assert all(record['checks'][name] is True for name in required)
 assert record['geometry_object_count']==m['expected_object_count'] and record['port_count']==m['port_count'] and record['monitor_count']==3 and record['spacecraft_panel_count']==m['spacecraft_panel_count']
 return m,record
