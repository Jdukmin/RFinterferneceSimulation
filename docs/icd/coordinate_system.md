# ICD — Coordinate System

This ICD **fixes** the coordinate conventions for the whole tool. All geometry code and tests
conform to it. (Requirements: SR-032, AR-010…AR-015.)

## 1. Frames

### 1.1 Spacecraft Body Frame (B)
- Right-handed Cartesian, origin at the spacecraft reference point.
- Axes `X_B, Y_B, Z_B` are defined by the spacecraft mechanical reference (this tool does not
  impose a specific mission axis meaning; it only requires a consistent right-handed frame).
- **All installation positions are expressed in B**, in meters.

### 1.2 Antenna Local Frame (A)
- Right-handed Cartesian, origin at the antenna installation reference point (phase/mount
  reference), located at `position_m` in B.
- **Boresight = +X_A** (canonical).
- **+Z_A = elevation-reference ("up") axis**; **+Y_A** completes the right-handed set
  (`Y_A = Z_A × X_A`).
- The antenna's orientation in B is given by the DCM `R_BA` (§3).

### 1.3 Pattern Frame (P)
- The frame in which a pattern's tabulated `(az_deg, el_deg)` are defined.
- **Canonical Phase-1 decision: P ≡ A** (the pattern frame equals the antenna local frame;
  `R_PA = I₃`).
- **Extension point:** a pattern-to-antenna mounting rotation `R_PA` (e.g., a pattern measured in
  a range frame rotated from the mechanical mount) is reserved. Phase-1 code assumes identity and
  documents that assumption; introducing `R_PA` later does not change the `AntennaPattern`
  contract.

## 2. Azimuth / Elevation Convention (canonical)

Defined in the antenna local frame A (equivalently P in Phase 1):

- **Boresight** is `az_deg = 0, el_deg = 0` → the `+X_A` axis.
- **Azimuth** `az_deg`: rotation about `+Z_A`, measured **from +X_A toward +Y_A**.
  Range **[−180, 180]**, **periodic** (wraps). `az = +180` and `az = −180` denote the same plane.
- **Elevation** `el_deg`: angle **above the X_A–Y_A plane toward +Z_A**.
  Range **[−90, 90]**, **bounded/clamped** (poles at ±90; not periodic).

### 2.1 Direction from (az, el) — canonical formula
```
u_A = [ cosd(el)*cosd(az) ;
        cosd(el)*sind(az) ;
        sind(el) ]           % unit vector in antenna frame A
```
`u_A` is a unit vector by construction.

### 2.2 (az, el) from a direction — canonical formula
Given any nonzero vector `v_A = [x; y; z]` in A:
```
r   = norm(v_A)
el  = asind( clamp(z / r, -1, +1) )    % → [-90, 90]
az  = atan2d( y, x )                   % → (-180, 180]
```
For the zero vector, az/el are **undefined**; callers must flag zero-separation (AR-015).

## 3. Rotation / DCM Convention (canonical)

- **`R_BA`** (stored on `AntennaInstallation`) is the 3×3 DCM whose **columns are the antenna
  frame axes expressed in body coordinates**. Therefore it maps antenna-frame vectors to body:
  ```
  v_B = R_BA * v_A
  ```
  - Column 1 of `R_BA` = boresight `+X_A` expressed in B.
  - Column 3 of `R_BA` = `+Z_A` expressed in B.
- **`R_AB = R_BA'`** (transpose = inverse, since orthonormal) maps body-frame vectors to antenna:
  ```
  v_A = R_AB * v_B = R_BA' * v_B
  ```
- **Round-trip invariant:** `v_A ≈ R_BA' * (R_BA * v_A)` (AR-014, VR-072).

### 3.1 Validity of a rotation matrix (rejected if violated — SR-034, VR-061)
`R` is a proper rotation iff: size 3×3, all finite, `‖RᵀR − I‖ ≤ tol_orth`, and
`det(R) ≥ 1 − tol_det` (proper, right-handed). Default tolerances: `tol_orth = 1e-9`,
`tol_det = 1e-6`.

### 3.2 Quaternion (SHOULD, SR-031)
Quaternion↔DCM conversion is provided as a convenience (`geometry.Rotation.fromQuaternion` /
`toQuaternion`), using the scalar-first convention `q = [w x y z]`, `‖q‖ = 1`. The **canonical
stored representation remains the DCM**; quaternions are only an input/output convenience.

## 4. Relative Geometry (pair)

Given body-frame positions `r_tx`, `r_rx` and DCMs `R_BA_tx`, `R_BA_rx`:

```
d_body       = r_rx - r_tx                 % body-frame TX→RX vector (m)
distance_m   = norm(d_body)
u_tx_A       = R_BA_tx' * (d_body / distance_m)     % TX→RX in TX antenna frame
u_rx_A       = R_BA_rx' * (-d_body / distance_m)    % RX→TX in RX antenna frame
[az_tx,el_tx]= dirToAzEl(u_tx_A)
[az_rx,el_rx]= dirToAzEl(u_rx_A)
```

Invariants (VR-070/071): `distance` symmetric; `d_rx→tx = −d_tx→rx`.

## 5. Angle Units

- **Public az/el are always in degrees** (`az_deg`, `el_deg`).
- Internal trigonometry may use radians but never leaks radians across a public boundary.
- Degree-based trig helpers (`cosd/sind/asind/atan2d`) are used to keep node values exact
  (e.g., `cosd(90)=0`).
