function [database_features, image_paths] = database_manager(db_option, cfg, progress_handler)
    if nargin < 3, progress_handler = []; end

    switch lower(db_option)
        case 'sample'
            [database_features, image_paths] = load_sample_database(cfg, progress_handler);
        case 'wang'
            [database_features, image_paths] = load_wang_database(cfg, progress_handler);
        case 'coral_10k'
            [database_features, image_paths] = load_coral_10k_database(cfg, progress_handler);
        case 'custom'
            % This triggers the folder selection
            [database_features, image_paths] = load_custom_database(cfg, progress_handler);
        otherwise
            error('Unknown database option');
    end
end

function [database_features, image_paths] = load_sample_database(cfg, progress_handler)
    sample_dir = 'datasets/sample';
    if ~isfolder(sample_dir), mkdir(sample_dir); end
    image_files = dir(fullfile(sample_dir, '*.png'));
    if isempty(image_files)
        create_sample_images();
        image_files = dir(fullfile(sample_dir, '*.png'));
    end
    [database_features, image_paths] = process_files(image_files, cfg, progress_handler);
end

function [database_features, image_paths] = load_wang_database(cfg, progress_handler)
    db_path = 'datasets/wang';
    if ~isfolder(db_path), error('WANG database folder not found!'); end
    image_files = [dir(fullfile(db_path, '**', '*.jpg')); dir(fullfile(db_path, '**', '*.png'))];
    [database_features, image_paths] = process_files(image_files, cfg, progress_handler);
end

function [database_features, image_paths] = load_coral_10k_database(cfg, progress_handler)
    db_path = 'datasets/coral_10k';
    if ~isfolder(db_path), error('CORAL database folder not found!'); end
    image_files = [dir(fullfile(db_path, '**', '*.jpg')); dir(fullfile(db_path, '**', '*.jpeg'))];
    [database_features, image_paths] = process_files(image_files, cfg, progress_handler);
end

function [database_features, image_paths] = load_custom_database(cfg, progress_handler)
    % Pop up folder selector
    custom_dir = uigetdir('', 'Select Your Group Images Folder');
    
    if custom_dir == 0
        error('No folder selected. Loading cancelled.');
    end
    
    % Find images recursively
    image_files = [dir(fullfile(custom_dir, '**', '*.jpg')); ...
                   dir(fullfile(custom_dir, '**', '*.png')); ...
                   dir(fullfile(custom_dir, '**', '*.jpeg'))];
                   
    if isempty(image_files)
        error('No images found in the selected folder!');
    end
    
    fprintf('Loading Custom Folder: %s\n', custom_dir);
    [database_features, image_paths] = process_files(image_files, cfg, progress_handler);
end

% --- SHARED PROCESSOR (Prevents code duplication) ---
function [database_features, image_paths] = process_files(image_files, cfg, progress_handler)
    num_images = length(image_files);
    database_features = struct('color', {}, 'texture', {}, 'shape', {}, 'deep', {}, 'combined', {});
    image_paths = {};
    
    for i = 1:num_images
        image_path = fullfile(image_files(i).folder, image_files(i).name);
        try
            database_features(i) = feature_extraction(image_path, cfg);
            image_paths{i} = image_path;
        catch
            % Skip failing images
        end
        if ~isempty(progress_handler), progress_handler(i, num_images); end
    end
end

function create_sample_images()
    if ~isfolder('datasets/sample'), mkdir('datasets/sample'); end
    for k = 1:15
        img = uint8(rand(200, 200, 3) * 255);
        imwrite(img, sprintf('datasets/sample/sample_%02d.png', k));
    end
end