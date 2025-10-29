Content-Based Image Retrieval (CBIR) plays a cru-
cial role in computer vision. It allows users to find similar images
by looking at their inherent features instead of text descriptions.
This paper shows how to design and build a CBIR system using
MATLAB. The system relies on three main visual aspects: color,
texture, and shape. To compare colors, it uses HSV histogram
processing and the Chi-square distance method. For texture,
it extracts features with the Gray-Level Co-occurrence Matrix
(GLCM) and Local Binary Patterns (LBP). Shape information
comes from edge-based Fourier descriptors. The system then
ranks images in the database based on how similar all these
features are leading to quick retrieval of related images. This
approach proves that combining multiple visual descriptors
improves retrieval accuracy compared to using just one feature.

