# CHIMERA-Wing-Optimization

Neural surrogate-enhanced multi-method framework for robust glider wing design optimization using VLM data, stability classification, and PSO, GA, Bayesian, MultiStart, and Lipschitz optimizers.

## Overview

CHIMERA, short for **Combined Hybrid Intelligent Multimethod Ensemble for Robust Aero-wing Optimization**, is a surrogate-assisted optimization framework for early-stage glider wing design.

The framework combines:

- Vortex Lattice Method aerodynamic data generation
- Neural-network surrogate modeling for aerodynamic prediction
- Neural-network classification for stability-label prediction
- Multiple optimization algorithms for design-space exploration
- Post-optimization aerodynamic and stability verification

The goal is to rapidly identify wing configurations that minimize drag while satisfying a target lift requirement and checking stability-related flight derivatives.

## Key Features

- Eight-variable glider wing design parameterization
- Aerodynamic surrogate for lift and drag prediction
- Stability classifier for selected static and damping derivative labels
- Multiple optimization methods:
  - Particle Swarm Optimization
  - Genetic Algorithm
  - MultiStart interior-point constrained optimization
  - Bayesian optimization
  - Adaptive Lipschitz search with local constrained refinement
- MATLAB-based optimization workflow
- Plotting tools for convergence, design-variable histories, and wing geometry
- Support for comparing neural-network predictions with VLM/EoM reference results

## Citation

If you use this repository, code, models, or results in academic work, please cite the associated paper.

## Design Variables

The optimization design vector is

```text
x = [root chord, angle of attack, sweep angle, span variable, twist angle, taper ratio, dihedral angle, velocity]
