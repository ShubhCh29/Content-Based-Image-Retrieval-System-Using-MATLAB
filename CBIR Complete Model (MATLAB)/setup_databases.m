function setup_databases()
    % ONE-TIME SETUP: Pre-compute features for datasets
    % Run this ONCE for each dataset before using GUI
    
    clear all
    close all
    clc
    
    fprintf('\n');
    fprintf('╔════════════════════════════════════════╗\n');
    fprintf('║   CBIR SYSTEM - DATABASE SETUP        ║\n');
    fprintf('║   Feature Pre-Processing (ONE-TIME)   ║\n');
    fprintf('╚════════════════════════════════════════╝\n\n');
    
    fprintf('This pre-computes ALL features ONCE.\n');
    fprintf('Results are cached for INSTANT retrieval!\n\n');
    
    % Add paths
    addpath(genpath('functions'));
    
    % Config
    cfg = config();
    cache_mgr = feature_cache_manager();
    
    % Menu
    fprintf('Select dataset to pre-process:\n');
    fprintf('─────────────────────────────────────────\n');
    fprintf('1️⃣  Sample (10 images - 30 seconds)\n');
    fprintf('2️⃣  WANG (1000 images - 30 minutes)\n');
    fprintf('3️⃣  CORAL 10K (1000 images - 30 minutes)\n');
    fprintf('4️⃣  All datasets\n\n');
    
    choice = input('Enter choice (1-4): ');
    
    switch choice
        case 1
            datasets = {'sample'};
        case 2
            datasets = {'wang'};
        case 3
            datasets = {'coral_10k'};
        case 4
            datasets = {'sample', 'wang', 'coral_10k'};
        otherwise
            datasets = {'sample'};
    end
    
    % Process each
    for d = 1:length(datasets)
        db_name = datasets{d};
        
        fprintf('\n');
        fprintf('╔════════════════════════════════════════╗\n');
        fprintf('║ Processing: %s\n', upper(db_name));
        fprintf('╚════════════════════════════════════════╝\n\n');
        
        try
            cache_mgr.precompute_dataset(db_name, cfg);
            fprintf('✓ %s setup complete!\n\n', upper(db_name));
        catch ME
            fprintf('✗ Error: %s\n\n', ME.message);
        end
    end
    
    fprintf('╔════════════════════════════════════════╗\n');
    fprintf('║ ✓ SETUP COMPLETE                      ║\n');
    fprintf('║ Run: cbir_gui_main                    ║\n');
    fprintf('╚════════════════════════════════════════╝\n\n');
end