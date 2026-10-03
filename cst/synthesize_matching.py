"""Circuit feasibility study only; never supplies CST matching PASS evidence."""
import argparse,json
from pathlib import Path
import numpy as np
from scipy.optimize import differential_evolution

def impedance(f,load,values,topology,q=np.inf):
    z=load.copy();w=2*np.pi*f*1e9
    for value,kind in zip(values,topology):
        x=w*value*1e-9 if kind.endswith('L') else -1/(w*value*1e-12)
        branch=np.abs(x)/q+1j*x
        z=z+branch if kind.startswith('series') else 1/(1/z+1/branch)
    return z

def main():
    parser=argparse.ArgumentParser();parser.add_argument('out');args=parser.parse_args()
    out=Path(args.out);d=np.load(out/'s_matrix.npz');f=d['frequency_ghz']
    indices=np.unique(np.linspace(0,len(f)-1,81).astype(int))
    # Identical matching at each symmetric arm preserves the quadrature mode.
    # This reduction is only valid when the intended excitation is an eigenmode.
    a=np.array([1,1j,-1,-1j]);s=d['s'];active=(s@a)/a
    modal=np.mean(active,axis=1);load=50*(1+modal)/(1-modal)
    mismatch=float(np.max(np.abs(active-modal[:,None])))
    cases=[]
    for topology in [('series_C','shunt_L'),
                     ('series_C','shunt_L','series_L','shunt_C'),
                     ('shunt_C','series_L','shunt_L','series_C'),
                     ('series_C','shunt_L','series_L','shunt_C','series_C','shunt_L')]:
        bounds=[(-1.3,1) if k.endswith('L') else (-1.3,.8) for k in topology]
        def objective(logvalues):
            z=impedance(f[indices],load[indices],10**logvalues,topology)
            return float(np.max(abs((z-50)/(z+50))))
        result=differential_evolution(objective,bounds,seed=17,maxiter=400,popsize=12,tol=1e-7)
        values=10**result.x;z=impedance(f,load,values,topology)
        rl=-20*np.log10(np.maximum(abs((z-50)/(z+50)),1e-15))
        zloss=impedance(f,load,values,topology,q=50)
        rlloss=-20*np.log10(np.maximum(abs((zloss-50)/(zloss+50)),1e-15))
        cases.append({'topology_load_to_source':topology,'values_nH_or_pF':values.tolist(),
                      'ideal_min_rl_db':float(rl.min()),'Q50_min_rl_db':float(rlloss.min()),
                      'finite_Q_note':'Return loss alone does not measure radiation efficiency or network dissipation.'})
    report={'status':'ANALYTICAL_FEASIBILITY_NOT_CST_PASS','modal_gamma_max_arm_deviation':mismatch,
            'frequency_band_ghz':[float(f.min()),float(f.max())],
            'assumptions':['identical per-arm network','ideal lumped elements; self resonance unverified',
                           'quadrature eigenmode reduction; verify symmetry before implementation'],
            'cases':cases}
    (out/'matching_feasibility.json').write_text(json.dumps(report,indent=2))
    for case in cases:print(case['topology_load_to_source'],round(case['ideal_min_rl_db'],2),case['values_nH_or_pF'])

if __name__=='__main__':main()
