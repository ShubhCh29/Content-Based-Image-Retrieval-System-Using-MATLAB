
# Content-Based Image Retrieval (CBIR) - MATLAB Implementation

This repository contains a MATLAB-based CBIR system that retrieves visually similar images using
color (HSV histogram), texture (GLCM), and shape (edge-based) descriptors. The WANG dataset (1,000 images) was used for testing, achieving 75% retrieval accuracy.

## How to Run
1. Place query image in `query/` folder.
2. Run `main.m` in MATLAB.
3. View top matching results and accuracy metrics.

## Features
- HSV color histogram for color similarity
- GLCM for texture representation
- Edge-based descriptors for shape analysis
- Weighted similarity computation for hybrid retrieval

## Dataset
WANG Dataset: [https://wang.ist.psu.edu/docs/related/](https://wang.ist.psu.edu/docs/related/)

## Authors
Shubh Chaudhary
Yuval Doshi
Gargi G. Maloo


---
