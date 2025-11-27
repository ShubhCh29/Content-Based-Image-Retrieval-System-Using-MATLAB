function cache_manager = feature_cache_manager()
    % Feature Caching System
    cache_manager.precompute_dataset = @precompute_dataset;
    cache_manager.load_cached_features = @load_cached_features;
    cache_manager.cache_exists = @cache_exists;
end

function precompute_dataset(db_name, cfg, progress_handler)
    % Pre-compute all features for a dataset and save to cache
    
    if nargin < 3
        progress_handler = [];
    end
    
    fprintf('PRE-PROCESSING: %s\n', db_name);
    
    % Pass progress_handler to database_manager
    [database_features, image_paths] = database_manager(db_option_map(db_name), cfg, progress_handler);
    
    if isempty(image_paths)
        error('No images loaded for preprocessing');
    end
    
    % Save to cache
    if ~isfolder('datasets'), mkdir('datasets'); end
    cache_file = sprintf('datasets/%s_features.mat', db_name);
    
    % Update progress bar one last time to show "Saving..."
    if ~isempty(progress_handler)
         % We can't update percentage here easily, but the loop is done
    end
    
    save(cache_file, 'database_features', 'image_paths', '-v7.3');
    fprintf('✓ Cache saved: %s\n', cache_file);
end

function [database_features, image_paths] = load_cached_features(db_name)
    cache_file = sprintf('datasets/%s_features.mat', db_name);
    if ~isfile(cache_file)
        error('Cache file not found! Run setup first.');
    end
    load(cache_file, 'database_features', 'image_paths');
end

function exists = cache_exists(db_name)
    cache_file = sprintf('datasets/%s_features.mat', db_name);
    exists = isfile(cache_file);
end

function opt = db_option_map(name)
    % Helper to map simple names to options
    if strcmpi(name, 'sample'), opt = 'sample';
    elseif strcmpi(name, 'wang'), opt = 'wang';
    elseif strcmpi(name, 'coral_10k'), opt = 'coral_10k';
    else, opt = 'custom';
    end
end