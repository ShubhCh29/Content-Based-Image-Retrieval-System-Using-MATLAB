function cbir_gui_main()
    % CBIR GUI - WITH CUSTOM DATASET SUPPORT
    
    % Create figure
    fig = uifigure();
    fig.Name = 'CBIR System - Custom Edition';
    fig.Position = [100 100 1400 800];
    
    % Add paths
    addpath(genpath('functions'));
    cfg = config();
    cache_mgr = feature_cache_manager();
    
    % State
    app_state = struct();
    app_state.cfg = cfg;
    app_state.cache_mgr = cache_mgr;
    app_state.database_features = [];
    app_state.image_paths = {};
    app_state.query_path = '';
    app_state.query_features = [];
    app_state.search_done = false;
    app_state.fig = fig;
    
    fig.UserData = app_state;
    
    % ==================== LAYOUT ====================
    % Left Sidebar (Controls)
    left_panel = uipanel(fig, 'Position', [10 10 400 780], 'Title', 'Controls');
    
    % Database
    uilabel(left_panel, 'Position', [10 730 200 20], 'Text', '1. Database:', 'FontWeight', 'bold');
    
    % === FIX IS HERE: ADDED 'Custom' TO THE ITEMS LIST ===
    db_dropdown = uidropdown(left_panel, 'Position', [10 700 180 25], ...
                            'Items', {'Sample', 'WANG', 'CORAL', 'Custom'}, ... 
                            'Value', 'Sample');
                            
    load_btn = uibutton(left_panel, 'Position', [200 700 180 25], ...
                       'Text', 'Load / Process', 'BackgroundColor', [0.2 0.7 0.2], 'FontColor', 'w');
    status_lbl = uilabel(left_panel, 'Position', [10 670 380 20], 'Text', 'Status: Idle', 'FontColor', [0.4 0.4 0.4]);
    
    % Query
    uilabel(left_panel, 'Position', [10 630 200 20], 'Text', '2. Query Image:', 'FontWeight', 'bold');
    browse_btn = uibutton(left_panel, 'Position', [10 600 370 25], ...
                         'Text', 'Browse Image...', 'BackgroundColor', [0.2 0.5 0.8], 'FontColor', 'w');
    
    query_ax = uiaxes(left_panel, 'Position', [10 330 370 260]);
    query_ax.Visible = 'off';
    title(query_ax, 'Query Image');
    
    % Search Settings
    uilabel(left_panel, 'Position', [10 290 200 20], 'Text', '3. Search Settings:', 'FontWeight', 'bold');
    
    uilabel(left_panel, 'Position', [10 260 80 20], 'Text', 'Top K:');
    topk_spinner = uispinner(left_panel, 'Position', [60 260 80 20], 'Value', 30, 'Limits', [5 100]);
    
    uilabel(left_panel, 'Position', [180 260 80 20], 'Text', 'Mode:');
    mode_dropdown = uidropdown(left_panel, 'Position', [230 260 150 20], ...
                              'Items', {'Combined', 'Color', 'Texture', 'Shape'}, 'Value', 'Combined');
    
    % Actions
    search_btn = uibutton(left_panel, 'Position', [10 200 370 40], ...
                         'Text', 'SEARCH DATABASE', 'FontSize', 14, 'FontWeight', 'bold', ...
                         'BackgroundColor', [0.1 0.6 1], 'FontColor', 'w');
                         
    viz_btn = uibutton(left_panel, 'Position', [10 150 180 30], ...
                      'Text', '3D Visualization', 'BackgroundColor', [0.7 0.2 1], 'FontColor', 'w');
                      
    save_btn = uibutton(left_panel, 'Position', [200 150 180 30], ...
                       'Text', 'Save Results', 'BackgroundColor', [1 0.6 0], 'FontColor', 'w');
                       
    stats_area = uitextarea(left_panel, 'Position', [10 10 370 130], 'Editable', 'off', ...
                           'FontName', 'monospace', 'Value', {'Ready.'});

    % ==================== RESULTS PANEL ====================
    uilabel(fig, 'Position', [420 760 300 30], 'Text', 'Search Results:', 'FontSize', 16, 'FontWeight', 'bold');
    
    results_panel = uipanel(fig, 'Position', [420 10 960 740], ...
                           'BackgroundColor', 'w', ...
                           'Scrollable', 'on'); 
    
    % ==================== CALLBACKS ====================
    load_btn.ButtonPushedFcn = @(src, event) load_db_callback(fig, db_dropdown, status_lbl);
    browse_btn.ButtonPushedFcn = @(src, event) browse_query_callback(fig, query_ax);
    search_btn.ButtonPushedFcn = @(src, event) search_callback(fig, topk_spinner, mode_dropdown, stats_area, results_panel);
    viz_btn.ButtonPushedFcn = @(src, event) viz_callback(fig);
    save_btn.ButtonPushedFcn = @(src, event) save_callback(fig);
end

%% CALLBACKS

function load_db_callback(fig, db_dropdown, status_lbl)
    app_state = fig.UserData;
    selection = db_dropdown.Value;
    
    % Map Selection to DB Name
    if contains(selection, 'Sample')
        db_name = 'sample';
    elseif contains(selection, 'WANG')
        db_name = 'wang';
    elseif contains(selection, 'Custom')
        db_name = 'custom';
    else
        db_name = 'coral_10k';
    end
    
    % Handle Custom "New vs Saved" Logic
    if strcmp(db_name, 'custom') && app_state.cache_mgr.cache_exists('custom')
        % Ask user if they want to reuse the saved custom data or load a NEW folder
        choice = uiconfirm(fig, ...
            'Found a previously saved Custom dataset. Do you want to load it, or select a new folder?', ...
            'Custom Dataset Found', ...
            'Options', {'Load Saved', 'Select New Folder'}, ...
            'DefaultOption', 'Load Saved', 'CancelOption', 'Load Saved');
            
        if strcmp(choice, 'Select New Folder')
            % Delete old cache to force re-selection
            delete('datasets/custom_features.mat');
        end
    end
    
    % PROGRESS BAR
    d = uiprogressdlg(fig, 'Title', 'Loading Database', 'Message', 'Initializing...', 'Cancelable', false);
    progress_handler = @(curr, total) update_prog_bar(d, curr, total, 'Processing Images');
    
    try
        if app_state.cache_mgr.cache_exists(db_name)
            d.Message = 'Loading from cache...'; d.Value = 0.9; pause(0.5);
            [app_state.database_features, app_state.image_paths] = ...
                app_state.cache_mgr.load_cached_features(db_name);
        else
            d.Message = 'Extracting features...';
            % If custom, this triggers folder selection inside database_manager
            app_state.cache_mgr.precompute_dataset(db_name, app_state.cfg, progress_handler);
            [app_state.database_features, app_state.image_paths] = ...
                app_state.cache_mgr.load_cached_features(db_name);
        end
        
        fig.UserData = app_state;
        status_lbl.Text = sprintf('✓ Loaded %d images', length(app_state.image_paths));
        status_lbl.FontColor = [0 0.5 0];
    catch ME
        status_lbl.Text = 'Error loading database';
        status_lbl.FontColor = [1 0 0];
        errordlg(ME.message, 'Error');
    end
    close(d);
end

function browse_query_callback(fig, query_ax)
    app_state = fig.UserData;
    [file, path] = uigetfile({'*.jpg;*.png;*.jpeg', 'Images'});
    if file == 0, return; end
    
    full_path = fullfile(path, file);
    app_state.query_path = full_path;
    
    imshow(imread(full_path), 'Parent', query_ax);
    query_ax.Visible = 'on';
    fig.UserData = app_state;
end

function search_callback(fig, topk_spinner, mode_dropdown, stats_area, results_panel)
    app_state = fig.UserData;
    
    if isempty(app_state.database_features), msgbox('Load database first!', 'Error'); return; end
    if isempty(app_state.query_path), msgbox('Select query image!', 'Error'); return; end
    
    % SEARCH PROGRESS BAR
    d = uiprogressdlg(fig, 'Title', 'Searching', 'Message', 'Extracting query features...', 'Indeterminate', 'on');
    
    try
        % 1. Extract Query
        app_state.query_features = feature_extraction(app_state.query_path, app_state.cfg);
        
        % 2. Search
        d.Message = 'Comparing against database...';
        
        search_results = feature_search_modes(app_state.query_features, ...
                                             app_state.database_features, app_state.cfg);
                                             
        mode = mode_dropdown.Value;
        if contains(mode, 'Color'), sims = search_results.color;
        elseif contains(mode, 'Texture'), sims = search_results.texture;
        elseif contains(mode, 'Shape'), sims = search_results.shape;
        else, sims = search_results.combined;
        end
        
        % 3. Sort
        d.Message = 'Sorting results...';
        [sorted_sims, sorted_idx] = sort(sims, 'descend');
        
        topk = topk_spinner.Value;
        topk = min(topk, length(sorted_idx));
        
        app_state.current_results.sims = sorted_sims(1:topk);
        app_state.current_results.idx = sorted_idx(1:topk);
        app_state.current_results.paths = app_state.image_paths(sorted_idx(1:topk));
        app_state.search_done = true;
        fig.UserData = app_state;
        
        % 4. Display (Grid)
        d.Message = 'Rendering results...';
        display_result_images(app_state, topk, results_panel);
        
        stats_area.Value = sprintf('Results for %s mode:\nTop Match: %.2f%%\nAvg (Top %d): %.2f%%', ...
            mode, sorted_sims(1), topk, mean(sorted_sims(1:topk)));
            
    catch ME
        msgbox(ME.message, 'Search Error');
    end
    close(d);
end

function display_result_images(app_state, topk, results_panel)
    % SCROLLABLE GRID IMPLEMENTATION
    delete(results_panel.Children);
    
    gl = uigridlayout(results_panel);
    gl.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
    gl.RowHeight = repmat({200}, 1, ceil(topk/5)); 
    gl.Scrollable = 'on';
    
    for i = 1:topk
        sim = app_state.current_results.sims(i);
        img_path = app_state.current_results.paths{i};
        
        card = uipanel(gl, 'BackgroundColor', 'w');
        if sim > 99, card.ForegroundColor = [0 0.5 0]; card.BorderWidth = 3; % Exact Match
        elseif sim > 80, card.ForegroundColor = [0 0.7 0];
        elseif sim > 50, card.ForegroundColor = [1 0.5 0];
        else, card.ForegroundColor = [1 0 0];
        end
        
        ax = uiaxes(card, 'Position', [5 25 150 160]);
        ax.Visible = 'off';
        try imshow(imread(img_path), 'Parent', ax); catch; end
        
        uilabel(card, 'Position', [5 5 150 20], ...
               'Text', sprintf('#%d: %.1f%%', i, sim), ...
               'HorizontalAlignment', 'center', ...
               'FontWeight', 'bold', 'FontColor', card.ForegroundColor);
    end
end

function viz_callback(fig)
    app_state = fig.UserData;
    if ~app_state.search_done, msgbox('Search first!', 'Error'); return; end
    
    num = min(50, length(app_state.current_results.idx));
    top_feat_cells = cell(num, 1);
    for i = 1:num
        idx = app_state.current_results.idx(i);
        if isstruct(app_state.database_features)
            top_feat_cells{i} = app_state.database_features(idx).combined;
        else
            top_feat_cells{i} = app_state.database_features{idx};
        end
    end
    plot_3d_analysis(app_state.query_features, top_feat_cells, app_state.current_results.sims(1:num));
end

function save_callback(fig)
    app_state = fig.UserData;
    if ~app_state.search_done, msgbox('Search first!'); return; end
    [f, p] = uiputfile('results.mat');
    if f, res = app_state.current_results; save(fullfile(p,f), 'res'); end
end

function update_prog_bar(d, curr, total, msg)
    d.Value = curr/total;
    d.Message = sprintf('%s: %d/%d', msg, curr, total);
end