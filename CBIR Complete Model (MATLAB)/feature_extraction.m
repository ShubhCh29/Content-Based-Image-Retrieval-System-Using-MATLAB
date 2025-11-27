function features = feature_extraction(image_path, cfg)
    % HIGH-SPEED FEATURE EXTRACTION
    % Vectorized LBP and Optimized Gabor
    
    try
        % Read and preprocess
        img = imread(image_path);
        
        if size(img, 3) == 4
            img = img(:, :, 1:3);
        elseif ismatrix(img)
            img = repmat(img, [1 1 3]);
        end
        
        img = imresize(img, cfg.preprocessing.image_size);
        img = im2double(img);
        
        % CLAHE
        if cfg.preprocessing.clahe_enabled
            try
                img_lab = rgb2lab(img);
                img_lab(:,:,1) = adapthisteq(img_lab(:,:,1), 'ClipLimit', 0.02);
                img = lab2rgb(img_lab);
            catch
            end
        end
        
        % Extract
        color_feat = extract_color_features_fast(img, cfg);
        texture_feat = extract_texture_features_fast(img, cfg);
        shape_feat = extract_shape_features_fast(img, cfg);
        deep_feat = extract_deep_features_fast(img, cfg);
        
        features.color = color_feat;
        features.texture = texture_feat;
        features.shape = shape_feat;
        features.deep = deep_feat;
        features.combined = [color_feat; texture_feat; shape_feat; deep_feat];
        
    catch ME
        % Return zeros on error to prevent crash
        warning('Skipping %s: %s', image_path, ME.message);
        features.color = zeros(1, 1); % Placeholder size, will be handled by similarity
        features.texture = zeros(1, 1);
        features.shape = zeros(1, 1);
        features.deep = zeros(1, 1);
        features.combined = [];
    end
end

%% ========== FAST COLOR ==========
function color_feat = extract_color_features_fast(img, cfg)
    img_hsv = rgb2hsv(img);
    bins = cfg.features.color_bins;
    
    h_hist = imhist(img_hsv(:,:,1), bins);
    s_hist = imhist(img_hsv(:,:,2), bins);
    v_hist = imhist(img_hsv(:,:,3), bins);
    
    % Moments
    [mh, sh] = get_moments(img_hsv(:,:,1));
    [ms, ss] = get_moments(img_hsv(:,:,2));
    [mv, sv] = get_moments(img_hsv(:,:,3));
    
    color_feat = [h_hist; s_hist; v_hist; mh; sh; ms; ss; mv; sv];
    color_feat = single(color_feat / (norm(color_feat) + eps));
end

function [m, s] = get_moments(c)
    m = mean(c, 'all'); s = std(c, 0, 'all');
end

%% ========== FAST TEXTURE ==========
function texture_feat = extract_texture_features_fast(img, cfg)
    img_gray = rgb2gray(img);
    img_gray = im2double(img_gray);
    
    % 1. Optimized Gabor
    scales = cfg.features.texture_gabor_scales;
    orientations = cfg.features.texture_gabor_orientations;
    gabor_feats = [];
    
    for s = 1:scales
        wavelength = 4 * 2^(s-1);
        for o = 1:orientations
            theta = (o-1) * pi / orientations;
            [mag, ~] = imgaborfilt(img_gray, wavelength, theta * 180/pi);
            gabor_feats = [gabor_feats; mean(mag, 'all'); std(mag, 0, 'all')];
        end
    end
    
    % 2. Vectorized LBP (High Speed)
    lbp_hist = extract_lbp_vectorized(img_gray);
    
    % 3. GLCM (Quantized for speed)
    img_quant = uint8(img_gray * 7);
    glcm = graycomatrix(img_quant, 'NumLevels', 8, 'Offset', [0 1], 'Symmetric', true);
    stats = graycoprops(glcm, {'Contrast', 'Energy', 'Homogeneity'});
    glcm_feat = [stats.Contrast; stats.Energy; stats.Homogeneity];
    
    texture_feat = [gabor_feats; lbp_hist; glcm_feat];
    texture_feat = single(texture_feat / (norm(texture_feat) + eps));
end

function lbp_hist = extract_lbp_vectorized(img_gray)
    [h, w] = size(img_gray);
    img = double(img_gray);
    center = img(2:h-1, 2:w-1);
    
    % 8-Neighbors vectorized comparison
    p1 = img(1:h-2, 1:w-2) >= center;
    p2 = img(1:h-2, 2:w-1) >= center;
    p3 = img(1:h-2, 3:w)   >= center;
    p4 = img(2:h-1, 3:w)   >= center;
    p5 = img(3:h,   3:w)   >= center;
    p6 = img(3:h,   2:w-1) >= center;
    p7 = img(3:h,   1:w-2) >= center;
    p8 = img(2:h-1, 1:w-2) >= center;
    
    lbp_map = uint8(p1 + p2*2 + p3*4 + p4*8 + p5*16 + p6*32 + p7*64 + p8*128);
    lbp_hist = imhist(lbp_map, 256);
    lbp_hist = lbp_hist / (sum(lbp_hist) + eps);
end

%% ========== FAST SHAPE ==========
function shape_feat = extract_shape_features_fast(img, cfg)
    img_gray = rgb2gray(img);
    bw = edge(img_gray, cfg.features.edge_detection, [0.1 0.3]);
    
    stats = regionprops(bw, 'Area', 'Perimeter', 'Eccentricity', 'Solidity');
    if isempty(stats)
        shape_feat = zeros(4, 1);
    else
        [~, idx] = max([stats.Area]);
        s = stats(idx);
        shape_feat = [s.Area; s.Perimeter; s.Eccentricity; s.Solidity];
    end
    shape_feat = single(shape_feat / (norm(shape_feat) + eps));
end

%% ========== FAST DEEP ==========
function deep_feat = extract_deep_features_fast(img, cfg)
    persistent net;
    if isempty(net)
        try net = resnet50; catch, try net = alexnet; catch, deep_feat=zeros(100,1); return; end; end
    end
    
    try
        input_size = net.Layers(1).InputSize(1:2);
        img_resized = imresize(img, input_size);
        if isa(net, 'SeriesNetwork') || isa(net, 'DAGNetwork')
            deep_feat = activations(net, img_resized, cfg.features.deep_layer, 'OutputAs', 'rows');
            deep_feat = deep_feat(:);
        else
            deep_feat = zeros(100,1);
        end
    catch
        deep_feat = zeros(100,1);
    end
    deep_feat = single(deep_feat / (norm(deep_feat) + eps));
end