function search_results = feature_search_modes(query_features, database_features, cfg)
    % Four search modes: Color, Texture, Shape, Combined
    % Returns similarity scores for each mode
    
    num_images = length(database_features);
    
    % Initialize results
    search_results.color = zeros(num_images, 1);
    search_results.texture = zeros(num_images, 1);
    search_results.shape = zeros(num_images, 1);
    search_results.deep = zeros(num_images, 1);
    search_results.combined = zeros(num_images, 1);
    
    % Compute individual feature similarities
    for i = 1:num_images
        if ~isempty(database_features(i).combined)
            
            % Color only
            search_results.color(i) = compute_sim(...
                query_features.color, ...
                database_features(i).color, 'hellinger') * 100;
            
            % Texture only
            search_results.texture(i) = compute_sim(...
                query_features.texture, ...
                database_features(i).texture, 'chi_square') * 100;
            
            % Shape only
            search_results.shape(i) = compute_sim(...
                query_features.shape, ...
                database_features(i).shape, 'cosine') * 100;
            
            % Deep learning
            search_results.deep(i) = compute_sim(...
                query_features.deep, ...
                database_features(i).deep, 'cosine') * 100;
            
            % Combined (weighted average)
            search_results.combined(i) = ...
                cfg.similarity.color_weight * search_results.color(i) + ...
                cfg.similarity.texture_weight * search_results.texture(i) + ...
                cfg.similarity.shape_weight * search_results.shape(i) + ...
                cfg.similarity.deep_weight * search_results.deep(i);
        end
    end
end

function sim = compute_sim(f1, f2, metric)
    % Quick similarity computation
    
    if isempty(f1) || isempty(f2)
        sim = 0;
        return;
    end
    
    min_len = min(length(f1), length(f2));
    f1 = f1(1:min_len);
    f2 = f2(1:min_len);
    
    switch lower(metric)
        case 'cosine'
            n1 = norm(f1); 
            n2 = norm(f2);
            % FIXED: Removed C-style ternary operator
            if n1 < eps || n2 < eps
                sim = 0;
            else
                sim = max(0, (f1'*f2)/(n1*n2));
            end
        case 'hellinger'
            dist = sqrt(sum((sqrt(abs(f1)) - sqrt(abs(f2))).^2)) / sqrt(2);
            sim = max(0, 1 - dist);
        case 'chi_square'
            denom = f1 + f2 + eps;
            dist = sum((f1-f2).^2 ./ denom);
            sim = 1 / (1 + dist);
        otherwise
            sim = 0;
    end
    
    sim = max(0, min(1, sim));
end