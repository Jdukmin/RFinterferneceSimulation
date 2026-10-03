"""Check coherent phase signs and power accounting independent of CST."""
import unittest
import numpy as np
from cst_results import active_reflection

class ActiveReflectionTests(unittest.TestCase):
    def test_uncoupled_and_coupled_quadrature(self):
        s=np.zeros((2,4,4),complex)
        s[0]=np.eye(4)*0.2
        s[1,0,1]=0.3
        g=active_reflection(s,[0,90,180,270])
        np.testing.assert_allclose(g[0],0.2,atol=1e-15)
        self.assertAlmostEqual(g[1,0].imag,0.3)
        self.assertAlmostEqual(g[1,0].real,0)

if __name__=='__main__':unittest.main()
