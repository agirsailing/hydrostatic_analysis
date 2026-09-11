# Simple Hull Hydrostatics (MATLAB)

A small MATLAB code for calculating the hydrostatics of a hull over a range of loading masses and outputs the **draught**, **waterplane area** and **displaced volume**.

It also includes a converter that turns an **STL hull model** into the **britfair (`.bri`)** section format the analysis uses.

The code builds on the hydrostatics routines used in the course **SD2721 Ship Design** at KTH Royal Institute of Technology.

---

## Contents

- [Requirements](#requirements)
- [Repository structure](#repository-structure)
- [Quick start](#quick-start)
- [Converting an STL file to `.bri`](#converting-an-stl-file-to-bri)
- [How it works](#how-it-works)
- [Limitations](#limitations)
- [The britfair (`.bri`) format](#the-britfair-bri-format)
- [Credits](#credits)

---

## Requirements

- **MATLAB R2018b or newer.** `bri_file.m` uses the built-in `stlread`, which was added in R2018b.
- No extra toolboxes are needed. The analysis only uses core functions such as `fzero` and `trapz`.

## Repository structure

```
.
├── simpleHydrostatics.m      # Main script: run this
├── bri_file.m                # STL -> .bri converter
├── CalculateHydrostatics.m   # Volume, centre of buoyancy, BM, GM, buoyancy force
├── ForceVertical.m           # Net vertical force (buoyancy - weight) for fzero
├── ReadHullGeometry.m        # Reads a .bri file and mirrors the half-sections
├── WetSections.m             # Intersects the hull with the water surface
├── WaveSurface.m             # Water surface (calm water by default)
├── TransMat.m                # Rotation matrix (roll, pitch, yaw)
├── TransShipfixedGlobal.m    # Ship-fixed -> global coordinates
├── TransGlobalShipfixed.m    # Global -> ship-fixed coordinates
├── polygonArea.m             # Signed area of a polygon
├── polygonCentroid.m         # Centroid of a polygon
├── QuickLines.m              # (Optional) interactive hull-form modification tool
└── HullGeometries/
    └── kayak.bri             # Example hull
```

> **Important:** `ReadHullGeometry.m` looks for hull files in a folder called `HullGeometries`. Put your `.bri` files there.
>
> On **macOS or Linux**, open `ReadHullGeometry.m` and change `'HullGeometries\'` to `'HullGeometries/'`.

## Quick start

1. Clone the repository and open the folder in MATLAB.
2. Make sure your hull file is in `HullGeometries/`. To create one from an STL, see [the next section](#converting-an-stl-file-to-bri).
3. Open `simpleHydrostatics.m` and edit the **USER INPUT** block:

   | Variable     | Description                                     | Unit |
   |--------------|-------------------------------------------------|------|
   | `hull_file`  | Name of the `.bri` file in `HullGeometries/`    | –    |
   | `LCG`        | Longitudinal centre of gravity, measured from the aft end | m |
   | `TCG`        | Transverse centre of gravity (0 = centreline)   | m    |
   | `KG`         | Vertical centre of gravity above the keel       | m    |
   | `mass_min`   | Lightest loading condition                      | kg   |
   | `mass_max`   | Heaviest loading condition                      | kg   |
   | `mass_step`  | Step between loading conditions                 | kg   |

   The water density `rho_water` is set under **FIXED PARAMETERS**. The default is 1025 kg/m³ (seawater). Use 1000 kg/m³ for fresh water.

4. Run the script:

   ```matlab
   simpleHydrostatics
   ```

### Output

The script prints a table to the Command Window with one row per loading mass. The header looks like this:

```
Mass [kg]     Draught [m]   Waterplane area [m^2]  Volume [m^3]
--------------------------------------------------------------
```

It also opens a figure with three plots against mass:

- draught,
- waterplane area,
- displaced volume.

## Converting an STL file to `.bri`

`bri_file.m` converts a hull surface mesh into britfair cross-sections.

1. Run `bri_file` in MATLAB.
2. Select your `.stl` file in the dialog.
3. The script writes two files to the current folder:
   - `kayak.bri`: the section file,
   - `kayak.csv`: the raw half-hull points, for checking.
4. It also shows a 3D scatter plot so you can inspect the result visually.
5. Move the `.bri` file into `HullGeometries/`. Rename it if you like.

### What the converter assumes about the STL

The converter works best when the mesh was exported so its vertices lie on transverse stations.

- **Units are millimetres.** Coordinates are divided by 1000 to convert to metres.
- **X is the longitudinal axis.** The hull is shifted so the aftmost point is at X = 0. If the hull lies mostly at negative X, it is mirrored first.
- **Z is flipped** so the keel ends up at the bottom, and shifted so the keel is at Z = 0. If your STL already has Z pointing up, remove the flip.
- **Y is the transverse axis.** Only the half with Y ≥ 0 is kept. Points within 5 mm of the centreline are snapped to Y = 0.
- **Sections are found by grouping vertices with the same X**, rounded to the nearest millimetre. This only gives clean sections if the vertices lie on transverse planes. A general triangulated mesh will produce scattered, unusable sections.
- **Points in each section are ordered by height (Z),** from keel to sheer. This works for normal section shapes. It can fail for unusual shapes where the outline doubles back in height.

## How it works

1. **Read the geometry.** `ReadHullGeometry` loads the half-sections from the `.bri` file and mirrors them into full sections.
2. **Place the ship-fixed origin at the centre of gravity.** The hull coordinates are shifted by `LCG`, `TCG` and `KG`.
3. **Find the floating position for each mass.** `fzero` searches the vertical position `eta3` between −8 m and +8 m until buoyancy equals weight:

   $$\rho \, g \, V(\eta_3) = m \, g$$

4. **Intersect the hull with the water.** `WetSections` does this for every section. The water surface is calm water at Z = 0. The polygon routines then give the wetted area $A(x)$ and waterline breadth $b(x)$ of each section.
5. **Integrate along the hull** with the trapezoidal rule:

   $$V = \int A(x)\,dx \qquad A_{wp} = \int b(x)\,dx \qquad T = KG - \eta_3$$

`CalculateHydrostatics` also computes the centre of buoyancy, $BM_0$, $KB_0$ and $GM_0$. These are available in the `HS` struct but are not printed by the main script.

## Limitations

- **Upright and even keel only.** Heel and trim are both fixed at zero, and only vertical force balance is solved. As a result, `LCG`, `TCG` and `KG` do **not** change the draught, waterplane area or volume in the output table. They only matter for the stability values in `HS`.
- **Calm water.** `WaveSurface.m` supports regular waves, but `simpleHydrostatics.m` does not use them.
- **The mass range may stop short of `mass_max`.** The masses are generated as `mass_min:mass_step:mass_max`, so the last value can be below `mass_max`.
- **`fzero` needs a sign change** between −8 m and +8 m. It fails with *"function values at the interval endpoints must differ in sign"* in two cases:
  - the mass is larger than the buoyancy of the fully submerged hull,
  - the hull is very large, or `KG` is more than a few metres.

  In those cases, reduce the mass range or widen the search interval.
- **Accuracy depends on section spacing.** More stations along the hull give better results.

## The britfair (`.bri`) format

A plain-text format that describes a hull as a series of half cross-sections, running from aft to forward.

```
<hull name>
1
<n_points> <x> <x>        <- section header: number of points, longitudinal position (twice)
<y_1> <z_1>               <- offsets from keel to sheer, half-breadth y and height z [m]
...
<y_n> <z_n>
0                         <- end of section
<n_points> <x> <x>        <- next section
...
0 0 0                     <- end of file
```

If the third value in a section header is `-999`, the block continues the previous section. This is used to mark knuckles in the section outline.

## Credits

- **Hydrostatics routines:** based on the course material for **SD2721 Ship Design**, KTH Royal Institute of Technology. The following files were written by Anders Rosén (KTH):
  - `ReadHullGeometry.m`,
  - `WetSections.m`,
  - `WaveSurface.m`,
  - `TransMat.m`, `TransShipfixedGlobal.m`, `TransGlobalShipfixed.m`,
  - `QuickLines.m`.
- **Polygon functions:** `polygonArea.m` and `polygonCentroid.m` were written by David Legland and come from the *geom2d* library, now part of MatGeom.
- **Additions in this repository:**
  - `simpleHydrostatics.m`: the mass-sweep script,
  - `bri_file.m`: the STL converter,
  - adaptations of `CalculateHydrostatics.m` and `ForceVertical.m`.

