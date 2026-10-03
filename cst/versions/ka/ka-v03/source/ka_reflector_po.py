"""Equivalent-paraboloid aperture integration for the Ka-band Cassegrain (NON-CST stage).

Learning Edition has no PO/asymptotic solver and a 100k-cell limit, so the D = 19
lambda reflector is not solved full-wave. Chain: feed co-pol gain Gf(psi) [from
CST or an analytic cos^n placeholder] -> Cassegrain equivalent paraboloid (focal
length Fe = M F) -> aperture field with subreflector blockage -> far field.

G(theta) = (k/2pi)^2 |Int sqrt(Gf(psi))/r' exp(j k rho sin(theta) cos(phi')) dA|^2 ((1+cos theta)/2)^2
with Gf normalised to the feed's accepted power (Int Gf dOmega = 4 pi), r' = Fe/cos^2(psi/2).
Spillover past the subreflector is lost from the main beam (accepted-power gain).
"""
import numpy as np
from scipy.special import j0

C0=299.792458  # mm*GHz

def aperture_gain(theta_deg,f_ghz,gf,D=220.0,Fe=368.0,Ds=44.0,n_rho=1200):
    """gf: callable psi[rad] -> linear feed co-pol gain (axisymmetric average)."""
    k=2*np.pi*f_ghz/C0
    rho=np.linspace(Ds/2,D/2,n_rho)
    psi=2*np.arctan(rho/(2*Fe));r=Fe/np.cos(psi/2)**2
    amp=np.sqrt(np.maximum(gf(psi),0))/r
    th=np.radians(np.atleast_1d(theta_deg))
    # azimuthal integral of exp(j k rho sin(th) cos(phi')) = 2 pi J0(k rho sin th)
    integ=np.array([np.trapezoid(amp*2*np.pi*j0(k*rho*np.sin(t))*rho,rho) for t in th])
    return (k/(2*np.pi))**2*np.abs(integ)**2*((1+np.cos(th))/2)**2

def cos_feed(n):
    """Analytic placeholder cos^n(psi) feed, forward hemisphere, normalised to 4 pi."""
    return lambda psi:2*(n+1)*np.where(psi<np.pi/2,np.cos(np.minimum(psi,np.pi/2))**n,0)

def self_test():
    """Silver closed form: cos^2 feed at F/D 0.38 (psi0 66.7 deg) -> 0.8288 aperture efficiency."""
    f=26.25;lam=C0/f
    eff=aperture_gain(0,f,cos_feed(2),D=220,Fe=0.38*220,Ds=1e-6)[0]/(np.pi*220/lam)**2
    assert abs(eff-0.8288)<1e-3,eff
    return eff

if __name__=='__main__':
    print('self-test Silver cos^2 F/D=0.38 aperture efficiency',round(self_test(),3))
