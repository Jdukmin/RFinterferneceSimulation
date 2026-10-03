import unittest
import numpy as np
from rfc_validation import metrics,sband_pass,export_screening,source_reference_metrics
from tempfile import TemporaryDirectory
from pathlib import Path

class RFCValidationTests(unittest.TestCase):
    def test_envelope_and_anchor_provenance(self):
        t=np.arange(360);g=np.ones(360)
        anchors=[{'theta_deg':60,'provenance':'PUBLIC_DATASHEET'},
                 {'theta_deg':61,'provenance':'PUBLIC_DATASHEET','interpolated':True},
                 {'theta_deg':180,'provenance':'ASSUMED_GEOMETRY'}]
        m=source_reference_metrics(t,g,np.zeros(360),anchors=anchors,
                                  lower=np.zeros(360),upper=2*np.ones(360))
        self.assertEqual(m['main_mae_db'],0)
        self.assertEqual(list(m['source_anchor_guards']),['60'])
        with self.assertRaises(ValueError):
            source_reference_metrics(t,g,g,upper=g)

    def test_back_null_does_not_improve_main_score_or_export(self):
        theta=np.arange(360);ref=np.zeros(360);gain=ref.copy();gain[180]=-90
        m=metrics(theta,gain,ref)
        self.assertEqual(m['main_mae_db'],0)
        with TemporaryDirectory() as d:
            rows=[{'theta':int(t),'gain':float(g),'target_gain':0} for t,g in zip(theta,gain)]
            result=export_screening(rows,Path(d)/'screen.csv',main_valid=True)
            self.assertEqual(result[180]['gain'],0)

    def test_good_pattern_without_matching_or_mesh_is_fail(self):
        t=np.arange(360);m=metrics(t,np.zeros(360),np.zeros(360))
        self.assertEqual(sband_pass(m,8)['overall'],'FAIL')
        self.assertEqual(sband_pass(m,15,True,True,True)['overall'],'FAIL')
        self.assertEqual(sband_pass(m,15,True,True,True,True,True,True,True)['overall'],'PASS')

    def test_accepted_power_matching_is_diagnostic_only(self):
        t=np.arange(360);m=metrics(t,np.zeros(360),np.zeros(360))
        result=sband_pass(m,4,True,True,True,True,True,True,True,
                          gain_basis='ACCEPTED_POWER_GAIN')
        self.assertEqual(result['overall'],'PASS')
        self.assertFalse(result['matching_required'])
        self.assertEqual(result['matching_role'],'DIAGNOSTIC_ONLY')
        self.assertEqual(sband_pass(m,4,True,True,True,True,True,True,True)['overall'],'FAIL')

if __name__=='__main__':unittest.main()
