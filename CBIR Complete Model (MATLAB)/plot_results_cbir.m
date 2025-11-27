function plot_results_cbir(query_path, top_results, image_paths, top_k)
    % Plot query image and top K results
    
    if nargin < 4
        top_k = 10;
    end
    
    figure('Name', 'Image Retrieval Results', 'NumberTitle', 'off', ...
           'Position', [100 100 1500 800]);
    
    % Query image
    subplot(2, 6, [1 7])
    query_img = imread(query_path);
    imshow(query_img)
    title('Query Image', 'FontSize', 14, 'FontWeight', 'bold')
    axis off
    
    % Top results
    num_results = min(top_k, length(top_results.overall));
    
    for i = 1:num_results
        subplot(2, 6, i + 2)
        
        result_idx = top_results.indices(i);
        result_path = image_paths{result_idx};
        result_img = imread(result_path);
        
        imshow(result_img)
        
        similarity = top_results.overall(i);
        if similarity > 75
            color = 'green';
        elseif similarity > 50
            color = 'orange';
        else
            color = 'red';
        end
        
        title(sprintf('%.1f%%', similarity), 'FontSize', 12, ...
              'FontWeight', 'bold', 'Color', color)
        axis off
    end
end

function plot_3d_analysis(query_features, database_features, similarity_scores)
    % 3D visualization using PCA
    
    figure('Name', '3D Feature Space Analysis', 'NumberTitle', 'off', ...
           'Position', [100 100 1200 900]);
    
    % Prepare data
    all_features = [query_features.combined; ...
                   cell2mat(database_features(:))];
    
    % PCA
    [coeff, score] = pca(all_features);
    score_3d = score(:, 1:3);
    
    % Plot 3D scatter
    subplot(2, 2, 1)
    scatter3(score_3d(2:end, 1), score_3d(2:end, 2), score_3d(2:end, 3), ...
            100, similarity_scores, 'filled', 'o', 'MarkerEdgeColor', 'black')
    hold on
    scatter3(score_3d(1, 1), score_3d(1, 2), score_3d(1, 3), ...
            200, 'r', 'pentagram', 'LineWidth', 2)
    colormap('cool')
    colorbar
    xlabel('PC1')
    ylabel('PC2')
    zlabel('PC3')
    title('Feature Space (PCA)')
    legend('Database Images', 'Query Image')
    grid on
    
    % Variance
    subplot(2, 2, 2)
    var_explained = sum(coeff.^2, 2);
    cumvar = cumsum(var_explained) / sum(var_explained) * 100;
    plot(cumvar(1:min(50, length(cumvar))), 'LineWidth', 2)
    xlabel('Principal Component')
    ylabel('Cumulative Variance (%)')
    title('Explained Variance')
    grid on
    
    % Similarity histogram
    subplot(2, 2, 3)
    histogram(similarity_scores, 20, 'FaceColor', 'cyan', 'EdgeColor', 'black')
    xlabel('Similarity Score')
    ylabel('Frequency')
    title('Similarity Distribution')
    grid on
    
    % Stats
    subplot(2, 2, 4)
    axis off
    stats_text = sprintf(['Statistics\n' ...
                         '===========\n' ...
                         'Mean: %.2f%%\n' ...
                         'Std: %.2f%%\n' ...
                         'Max: %.2f%%\n' ...
                         'Min: %.2f%%'], ...
                         mean(similarity_scores), ...
                         std(similarity_scores), ...
                         max(similarity_scores), ...
                         min(similarity_scores));
    text(0.1, 0.5, stats_text, 'FontSize', 12, 'FontName', 'monospace')
end