function cbir_engine()
    % Main CBIR Engine - Updated for WANG dataset
    % This is the script you RUN to use the system
    
    clear all
    close all
    clc
    
    fprintf('\n========================================\n');
    fprintf('CONTENT-BASED IMAGE RETRIEVAL SYSTEM\n');
    fprintf('========================================\n\n');
    
    % Add paths
    addpath(genpath('functions'));
    
    % Load configuration
    cfg = config();
    
    % Step 1: Load Database
    fprintf('Step 1: Loading Database...\n');
    fprintf('-----------------------------------------\n');
    fprintf('Options:\n');
    fprintf('1. sample (built-in sample images)\n');
    fprintf('2. wang (WANG dataset)\n');
    fprintf('3. coral_10k (CORAL 10K dataset)\n');
    fprintf('4. custom (choose your own folder)\n\n');
    
    choice = input('Enter choice (1-4): ');
    
    switch choice
        case 1
            db_option = 'sample';
        case 2
            db_option = 'wang';
        case 3
            db_option = 'coral_10k';
        case 4
            db_option = 'custom';
        otherwise
            db_option = 'sample';
            fprintf('Invalid choice. Using sample database.\n');
    end
    
    [database_features, image_paths] = database_manager(db_option, cfg);
    
    if isempty(image_paths)
        error('No images loaded. Please check your database folder.');
    end
    
    fprintf('✓ Database loaded with %d images\n\n', length(image_paths));
    
    % Step 2: Select Query Image
    fprintf('Step 2: Select Query Image...\n');
    fprintf('-----------------------------------------\n');
    
    [query_file, query_path] = uigetfile({'*.jpg; *.jpeg; *.png; *.tif; *.JPG; *.PNG', ...
        'Image Files'}, 'Select Query Image');
    
    if query_file == 0
        error('No query image selected');
    end
    
    query_image_full_path = fullfile(query_path, query_file);
    fprintf('✓ Query image selected: %s\n\n', query_file);
    
    % Step 3: Set Number of Results
    fprintf('Step 3: Set Number of Results...\n');
    fprintf('-----------------------------------------\n');
    fprintf('Options: 10, 15, 20, 25, 30\n\n');
    
    num_results = input('Enter number of results (10-30): ');
    
    if num_results < 10 || num_results > 30
        num_results = 10;
        fprintf('Invalid input. Using 10 results.\n');
    end
    
    fprintf('✓ Number of results set to: %d\n\n', num_results);
    
    % Step 4: Set Similarity Threshold
    fprintf('Step 4: Set Similarity Threshold...\n');
    fprintf('-----------------------------------------\n');
    fprintf('Range: 0-100 (percentage)\n\n');
    
    threshold = input('Enter threshold (0-100): ');
    
    if threshold < 0 || threshold > 100
        threshold = 50;
        fprintf('Invalid input. Using 50.\n');
    end
    
    fprintf('✓ Threshold set to: %.0f%%\n\n', threshold);
    
    % Step 5: Extract Query Features
    fprintf('Step 5: Extracting Query Features...\n');
    fprintf('-----------------------------------------\n');
    
    query_features = feature_extraction(query_image_full_path, cfg);
    fprintf('✓ Query features extracted\n\n');
    
    % Step 6: Compute Similarities
    fprintf('Step 6: Computing Similarities...\n');
    fprintf('-----------------------------------------\n');
    
    sim_scores = similarity_computation(query_features, database_features, cfg);
    fprintf('✓ Similarities computed\n\n');
    
    % Step 7: Sort Results
    fprintf('Step 7: Sorting Results...\n');
    fprintf('-----------------------------------------\n');
    
    [sorted_sims, sorted_indices] = sort(sim_scores.overall, 'descend');
    
    top_k = min(num_results, length(sorted_indices));
    
    top_results.overall = sorted_sims(1:top_k);
    top_results.color = sim_scores.color(sorted_indices(1:top_k));
    top_results.texture = sim_scores.texture(sorted_indices(1:top_k));
    top_results.shape = sim_scores.shape(sorted_indices(1:top_k));
    top_results.deep = sim_scores.deep(sorted_indices(1:top_k));
    top_results.indices = sorted_indices(1:top_k);
    top_results.image_paths = image_paths(sorted_indices(1:top_k));
    
    fprintf('✓ Results sorted\n\n');
    
    % Step 8: Display Results
    fprintf('========================================\n');
    fprintf('SEARCH RESULTS\n');
    fprintf('========================================\n\n');
    fprintf('Top Match: %.2f%% Similarity\n', top_results.overall(1));
    fprintf('Average Similarity: %.2f%%\n', mean(top_results.overall));
    fprintf('Images Above Threshold: %d\n\n', sum(top_results.overall >= threshold));
    
    % Display top 5 results
    fprintf('Top 5 Results:\n');
    for i = 1:min(5, length(top_results.overall))
        fprintf('  %d. %.2f%% Similarity\n', i, top_results.overall(i));
    end
    fprintf('\n');
    
    % Step 9: Visualize
    fprintf('Step 9: Visualization...\n');
    fprintf('-----------------------------------------\n');
    
    plot_results_cbir(query_image_full_path, top_results, image_paths, top_k);
    fprintf('✓ Results plotted\n\n');
    
    % Step 10: Ask for 3D Analysis
    fprintf('Step 10: 3D Nerd Analysis (Optional)...\n');
    fprintf('-----------------------------------------\n');
    
    show_3d = input('Show 3D feature space analysis? (y/n): ', 's');
    
    if strcmpi(show_3d, 'y')
        top_features = {};
        for i = 1:length(top_results.indices)
            idx = top_results.indices(i);
            top_features{i} = database_features(idx).combined;
        end
        
        plot_3d_analysis(query_features, top_features, top_results.overall);
        fprintf('✓ 3D analysis plotted\n\n');
    end
    
    % Step 11: Save Results
    fprintf('Step 11: Save Results (Optional)...\n');
    fprintf('-----------------------------------------\n');
    
    save_results = input('Save results to file? (y/n): ', 's');
    
    if strcmpi(save_results, 'y')
        results.query_image = query_file;
        results.num_results = top_k;
        results.threshold = threshold;
        results.top_similarities = top_results.overall;
        results.top_image_paths = top_results.image_paths;
        results.timestamp = datetime('now');
        
        if ~isfolder('results')
            mkdir('results');
        end
        
        save('results/cbir_results.mat', 'results');
        fprintf('✓ Results saved to: results/cbir_results.mat\n\n');
    end
    
    fprintf('========================================\n');
    fprintf('SEARCH COMPLETE!\n');
    fprintf('========================================\n\n');
end