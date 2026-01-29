
# Content-Based Image Retrieval (CBIR) - MATLAB Implementation

This repository contains a MATLAB-based CBIR system that retrieves visually similar images using
color (HSV histogram), texture (GLCM, LBP), and shape (edge-based) descriptors (Canny, Hu Moments). The WANG dataset (1,000 images) was used for testing and COREL-10k dataset was used for the completed CBIR model, achieving over 90% retrieval accuracy.

## How to Run
1. Place query image in `query/` folder.
2. Run `cbir_engine.m` in MATLAB.
3. View top matching results and accuracy metrics.

## Features
- HSV color histogram for color similarity.
- GLCM and LBP for texture representation.
- Edge-based descriptors (Canny and Hu Moments) for shape analysis.
- Weighted similarity computation for hybrid retrieval.
- Deep Learning Integration using ResNet-50 (Deep CNN).

## Dataset
- WANG Dataset: [https://wang.ist.psu.edu/docs/related/](https://wang.ist.psu.edu/docs/related/)
- COREL-10K Dataset: [https://www.kaggle.com/datasets/michelwilson/corel10k](https://www.kaggle.com/datasets/michelwilson/corel10k)

## Authors
Shubh Chaudhary


---
