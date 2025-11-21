function [Value_data] = Info_fusion(Value_data, Graph, Value_Params)
% =========================================================================
% Info_fusion: 信息融合函数
% =========================================================================
% 功能描述：
%   通过分布式共识算法实现智能体间的信息融合，包括：
%   1. 计算局部信念（基于个体观测数据）
%   2. 转换为共性函数（对数域）
%   3. 通过Metropolis-Hastings权重进行线性共识
%   4. 转换回信念值并归一化
%
% 输入参数：
%   Value_data: 包含观测数据的智能体信息结构体数组
%   Graph: 通信拓扑邻接矩阵 (N×N)
%   Value_Params: 参数结构体，包含N（智能体数量）、M（任务数量）
%
% 输出参数：
%   Value_data: 更新后的智能体信息结构体数组，包含融合后的信念
%
% 算法原理：
%   使用线性共识算法在对数域进行信念融合，确保所有智能体
%   基于融合信息达成一致性信念，为联盟形成提供统一的决策基础
% =========================================================================

%% 第一步：计算局部信念（基于个体观测数据）
for i = 1:Value_Params.N
    for j = 1:Value_Params.M
        % 计算智能体i对任务j的总观测次数
        total_obs = Value_data(i).observe(j,1) + Value_data(i).observe(j,2) + Value_data(i).observe(j,3);
        
        if total_obs > 0
            % 基于自己的观测次数计算信念概率：观测某类型次数/总观测次数
            Value_data(i).initbelief(j,1) = Value_data(i).observe(j,1) / total_obs;
            Value_data(i).initbelief(j,2) = Value_data(i).observe(j,2) / total_obs;
            Value_data(i).initbelief(j,3) = Value_data(i).observe(j,3) / total_obs;
        else
            % 如果没有观测数据，保持均匀分布
            Value_data(i).initbelief(j,1:end) = [1/3, 1/3, 1/3];
        end
    end
end

%% 第二步：计算共性函数（信念值的对数变换）
for i = 1:Value_Params.N
    for j = 1:Value_Params.M
        for k = 1:3
            % 对信念值取对数得到共性函数
            % 添加小常数避免log(0)的数值问题
            epsilon = 1e-10;
            Value_data(i).commonality(j,k) = log(Value_data(i).initbelief(j,k) + epsilon);
        end
    end
end

%% 第三步：计算Metropolis-Hastings权重矩阵
W = zeros(Value_Params.N, Value_Params.N);

for i = 1:Value_Params.N
    % 找到智能体i的邻居（包括自己）
    neighbors_i = find(Graph(i,:) > 0);
    neighbors_i = [neighbors_i, i]; % 添加自己
    neighbors_i = unique(neighbors_i); % 去除重复
    degree_i = length(neighbors_i) - 1; % 邻居数量（不包括自己）
    
    for j = 1:Value_Params.N
        if i == j
            % 对角元素：W(i,i) = 1 - sum(W(i,j)) for j≠i
            W(i,i) = 0; % 先设为0，后面计算
        elseif Graph(i,j) > 0 % i和j是邻居
            neighbors_j = find(Graph(j,:) > 0);
            neighbors_j = [neighbors_j, j];
            neighbors_j = unique(neighbors_j);
            degree_j = length(neighbors_j) - 1;
            
            % Metropolis-Hastings权重公式
            W(i,j) = 1 / (1 + max(degree_i, degree_j));
        else
            % 非邻居节点权重为0
            W(i,j) = 0;
        end
    end
    
    % 计算对角元素，确保行和为1
    W(i,i) = 1 - sum(W(i,1:Value_Params.N)) + W(i,i);
end

%% 第四步：线性共识算法
% 共识参数设置
max_consensus_iter = 20;  % 最大共识迭代次数
consensus_tolerance = 1e-4;  % 收敛容忍度

% 将共性函数重新组织为矩阵形式便于计算
% X(i, j*3+k-2) = commonality(j,k) for agent i
X = zeros(Value_Params.N, Value_Params.M * 3);
for i = 1:Value_Params.N
    for j = 1:Value_Params.M
        for k = 1:3
            col_idx = (j-1)*3 + k;  % 列索引：任务j的类型k
            X(i, col_idx) = Value_data(i).commonality(j,k);
        end
    end
end

% 线性共识迭代：X(t+1) = W * X(t)
for consensus_iter = 1:max_consensus_iter
    X_old = X;
    
    % 状态更新：每个智能体的状态是邻居状态的加权平均
    X = W * X;
    
    % 检查收敛性：所有智能体的状态变化是否足够小
    max_change = max(max(abs(X - X_old)));
    if max_change < consensus_tolerance
        fprintf('共识算法在第 %d 次迭代后收敛\n', consensus_iter);
        break;
    end
end

% 将更新后的共识结果写回到各智能体的共性函数中
for i = 1:Value_Params.N
    for j = 1:Value_Params.M
        for k = 1:3
            col_idx = (j-1)*3 + k;
            Value_data(i).commonality(j,k) = X(i, col_idx);
        end
    end
end

%% 第五步：转换回信念值并归一化
for i = 1:Value_Params.N
    for j = 1:Value_Params.M
        for k = 1:3
            Value_data(i).initbelief(j,k) = exp(Value_data(i).commonality(j,k));
        end
        % 归一化信念值
        total_belief = sum(Value_data(i).initbelief(j,:));
        if total_belief > 0
            Value_data(i).initbelief(j,:) = Value_data(i).initbelief(j,:) / total_belief;
        else
            % 如果归一化分母为0，保持均匀分布
            Value_data(i).initbelief(j,:) = [1/3, 1/3, 1/3];
        end
    end
end

end
