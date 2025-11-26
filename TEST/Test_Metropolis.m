% 1. 设置测试参数（对应上述拓扑）
Value_Params.N = 5;  % 节点数N=3
% 邻接矩阵Graph（无向图，对称）
Graph = [
    0, 1, 1,0, 0;  % 节点1的邻居：2
    1, 0, 0, 0, 0;  % 节点2的邻居：1、3
    1,0,0,1,1;  % 节点3的邻居：2
    0,0,1,0,0; 
    0,0,1,0,0; 
];

% 2. 你的原始代码（未修改，直接运行）
W = zeros(Value_Params.N, Value_Params.N);
for i = 1:Value_Params.N
    % 找到智能体i的邻居（包括自己）
    neighbors_i = find(Graph(i,:) > 0);
    neighbors_i = [neighbors_i, i]; % 添加自己
    neighbors_i = unique(neighbors_i); % 去除重复
    degree_i = length(neighbors_i) - 1; % 邻居数量（不包括自己）
    
    for j = 1:Value_Params.N
        if i == j
            W(i,i) = 0; % 先设为0，后面计算
        elseif Graph(i,j) > 0 % i和j是邻居
            neighbors_j = find(Graph(j,:) > 0);
            neighbors_j = [neighbors_j, j];
            neighbors_j = unique(neighbors_j);
            degree_j = length(neighbors_j) - 1;
            
            % Metropolis-Hastings权重公式（与文献一致）
            W(i,j) = 1 / (1 + max(degree_i, degree_j));
        else
            W(i,j) = 0;
        end
    end
    
    % 计算对角元素，确保行和为1（代码中+W(i,i)冗余，但不影响结果）
    W(i,i) = 1 - sum(W(i,1:Value_Params.N)) + W(i,i);
end

% 3. 输出结果，对比正确矩阵
fprintf('代码输出的W矩阵：\n');
disp(W);
