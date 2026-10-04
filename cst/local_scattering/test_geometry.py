"""Geometry invariants that guard physical positions, frames and real facets."""
import unittest
import numpy as np
from .geometry import local_facets,INSTALLATIONS,VERTICES,EDGES

class GeometryTests(unittest.TestCase):
    def test_reference_and_frame(self):
        for name,(position,z,mount,family) in INSTALLATIONS.items():
            g=local_facets(name,2.25,3)
            frame=np.array(g['local_to_body_rotation'])
            np.testing.assert_allclose(frame.T@frame,np.eye(3),atol=1e-12)
            self.assertAlmostEqual(np.linalg.det(frame),1.)
            self.assertEqual(g['position_mm'],position)
            for facet in g['facets']:
                body=np.array(facet['points_local_mm'])@frame.T+position
                if facet['panel']==8:
                    np.testing.assert_allclose(body[:,0],0,atol=1e-10)
                else:
                    a,b=(VERTICES[i] for i in EDGES[facet['panel']-1])
                    v=b-a;relative=body[:,1:]-a
                    np.testing.assert_allclose(relative[:,0]*v[1]-relative[:,1]*v[0],0,atol=1e-6)

    def test_rear_is_not_plane_distance(self):
        expected={'SBA_NADIR':[1,6,8],'SBA_ZENITH':[3,4,8]}
        for name,panels in expected.items():
            g=local_facets(name,2.25,3)
            self.assertEqual(g['included_panels'],panels)
            self.assertEqual(g['x_extent_mm'][0],0.)
            rear=g['structure_distances'][-1]
            self.assertEqual(rear['plane_distance_mm'],255.)
            self.assertGreater(rear['finite_facet_distance_mm'],255.)

    def test_gps_rear_outside_crop(self):
        for name in ['GPSA_1','GPSA_2']:
            g=local_facets(name,1.57542,3)
            self.assertEqual(g['included_panels'],[3,4])
            self.assertGreater(g['x_extent_mm'][0],0.)

if __name__=='__main__':unittest.main()
