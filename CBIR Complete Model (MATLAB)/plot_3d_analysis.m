function plot_3d_analysis(query_features, top_features_cell, similarity_scores)
    % 3D VISUALIZATION
    % Visualizes the query image and search results in a 3D PCA space.
    
    % Create figure
    f = figure('Name', '3D Analysis', 'Position', [100 100 1200 800]);
    
    try
        % 1. Prepare Data
        % Query vector (1 x D)
        q_vec = double(query_features.combined(:)'); 
        query_dim = length(q_vec);
        
        % Database vectors (N x D)
        % Handle cases where top_features_cell might be empty or wrong shape
        if isempty(top_features_cell)
            error('No image features provided for visualization.');
        end
        
        % Convert cell array of features to a matrix
        % We transpose (x(:)') each feature to ensure it's a row vector
        db_rows = cellfun(@(x) double(x(:)'), top_features_cell, 'UniformOutput', false);
        db_mat = cell2mat(db_rows);
        
        % 2. Safety Check
        if size(db_mat, 2) ~= query_dim
            error('Dimension mismatch! Query: %d, Database: %d. Please Clear Cache.', ...
                  query_dim, size(db_mat, 2));
        end
        
        % 3. Combine for PCA
        all_data = [q_vec; db_mat];
        
        % 4. Run PCA
        [coeff, score] = pca(all_data);
        
        % Handle cases with too few dimensions (less than 3 images)
        if size(score, 2) < 3
            score = [score, zeros(size(score,1), 3-size(score,2))];
        end
        
        score_3d = score(:, 1:3);
        
        % 5. Plotting
        subplot(2,2,1);
        
        % Plot Query (Red Star)
        scatter3(score_3d(1,1), score_3d(1,2), score_3d(1,3), 300, 'p', ...
                'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', ...
                'DisplayName', 'Query Image');
        hold on;
        
        % Plot Results (Colored circles)
        num_results = size(score_3d, 1) - 1;
        
        % Match colors to number of points
        if length(similarity_scores) > num_results
            current_sims = similarity_scores(1:num_results);
        else
            current_sims = similarity_scores;
        end
        
        scatter3(score_3d(2:end,1), score_3d(2:end,2), score_3d(2:end,3), ...
                100, current_sims, 'filled', 'o', 'MarkerEdgeColor', 'k', ...
                'DisplayName', 'Results');
                
        colormap('jet'); 
        c = colorbar;
        c.Label.String = 'Similarity (%)';
        
        xlabel('PC1'); ylabel('PC2'); zlabel('PC3');
        title('Feature Space Distribution');
        grid on;
        legend('show');
        
        % Variance Plot
        subplot(2,2,2);
        explained = sum(coeff.^2, 2);
        if sum(explained) > 0
            plot(cumsum(explained)/sum(explained)*100, '-o', 'LineWidth', 2);
        end
        title('Explained Variance'); ylabel('Cumulative %'); grid on;
        
        % Similarity Histogram
        subplot(2,2,3);
        histogram(similarity_scores, 10, 'FaceColor', 'b');
        title('Similarity Distribution');
        xlabel('Similarity Score');
        
    catch ME
        close(f);
        errordlg(sprintf('Visualization Error: %s', ME.message), 'Error');
    end
end