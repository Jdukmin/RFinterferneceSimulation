"""Actual CST rendering using installed VBA syntax, not Python geometry plots."""
import json
from pathlib import Path
from cst_com_common import add_to_history

def structure_image(p,path):
    raise RuntimeError('Do not add rendering commands to History after a solve: CST requests result invalidation. Use a standalone graphics macro or a real GUI screenshot.')
    # Retained below only as syntax reference; not executed.
    path=Path(path).resolve();path.parent.mkdir(parents=True,exist_ok=True)
    # Installed Library/Includes/video_creation.lib, ExportImage subroutine:
    # ExportImageToFile (MakeNativePath(tempfile), videowidth, videoheight)
    # This is a global VBA function, not a guessed Plot COM method.
    add_to_history(p,'Actual CST structure rendering',
                   f'ResetViewToStructure\nPlot.ZoomToStructure\nExportImageToFile ("{path}", 1200, 900)')
    if not path.exists() or path.stat().st_size<1000:
        raise RuntimeError('CST did not produce a usable image file')
    path.with_suffix('.provenance.json').write_text(json.dumps({
        'producer':'CST_NATIVE_VBA_RENDER','syntax_source':'CST 2026 Library/Includes/video_creation.lib:499-504',
        'view':'current structure view; requires visual inspection','python_geometry_plot':False,
        'image':str(path)},indent=2))
    return path
