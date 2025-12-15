function W = Metropolis_Hastings_Weights(Graph, Value_Params)
    % computeMetropolisHastingsWeights 计算 Metropolis-Hastings 权重矩阵
    % 输入：
    %   Graph         - 邻接矩阵，表示智能体之间的连接（Value_Params.N x Value_Params.N）
    %   Value_Params  - 包含智能体数量 N 的结构体
    % 输出：
    %   W             - 计算出的权重矩阵

    % 初始化权重矩阵
    W = zeros(Value_Params.N, Value_Params.N);
    
    % 遍历每个智能体
    for i = 1:Value_Params.N
        % 找到智能体 i 的邻居（包括自己）
        neighbors_i = find(Graph(i,:) > 0);
        neighbors_i = [neighbors_i, i];  % 添加自己
        neighbors_i = unique(neighbors_i);  % 去除重复
        degree_i = length(neighbors_i) - 1;  % 邻居数量（不包括自己）

        % 遍历每个智能体
        for j = 1:Value_Params.N
            if i == j
                % 对角元素：初始化为0，后续计算
                W(i,i) = 0;
            elseif Graph(i,j) > 0  % 如果 i 和 j 是邻居
                % 找到智能体 j 的邻居
                neighbors_j = find(Graph(j,:) > 0);
                neighbors_j = [neighbors_j, j];
                neighbors_j = unique(neighbors_j);
                degree_j = length(neighbors_j) - 1;

                % 使用 Metropolis-Hastings 权重公式计算 W(i, j)
                W(i,j) = 1 / (1 + max(degree_i, degree_j));
            else
                % 非邻居节点的权重为0
                W(i,j) = 0;
            end
        end

        % 计算对角元素，确保行和为1
        W(i,i) = 1 - sum(W(i,1:Value_Params.N)) + W(i,i);
    end
end
