function cfg = config()
    % CONFIGURATION - OPTIMIZED FOR SPEED & SCROLLING
    
    cfg.database_paths = struct();
    cfg.database_paths.wang = 'datasets/wang/';
    cfg.database_paths.coral_10k = 'datasets/coral_10k/';
    cfg.database_paths.sample = 'datasets/sample/';
    
    % ===== FEATURE EXTRACTION (SPEED OPTIMIZED) =====
    % Color
    cfg.features.color_bins = 64;               % Optimized from 128
    cfg.features.color_space = 'HSV';
    
    % Texture (Heavily Optimized)
    cfg.features.texture_gabor_scales = 3;      % Reduced from 5
    cfg.features.texture_gabor_orientations = 4; % Reduced from 8
    cfg.features.lbp_radius = 1;
    
    % Shape
    cfg.features.edge_detection = 'canny';      % Matches feature_extraction logic
    
    % Deep Learning
    cfg.features.deep_layer = 'fc1000';         % Usually faster to access
    cfg.features.deep_dimension = 1000;
    
    % Preprocessing
    cfg.preprocessing.image_size = [256 256];   
    cfg.preprocessing.normalize = true;
    cfg.preprocessing.clahe_enabled = true;
    
    % ===== SIMILARITY PARAMETERS =====
    cfg.similarity.color_weight = 0.30;
    cfg.similarity.texture_weight = 0.20;
    cfg.similarity.shape_weight = 0.10;
    cfg.similarity.deep_weight = 0.40;
    cfg.similarity.metric = 'cosine';
    
    % ===== GUI PARAMETERS =====
    cfg.gui.max_results = 100;     % Increased since we have scrolling now
    cfg.gui.thumbnail_size = [150 150];
    
    % ===== CACHING =====
    cfg.cache.enabled = true;
end