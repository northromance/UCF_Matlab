function [Value_data] = Info_fusion(Value_data, Graph, Value_Params)

% 共识参数设置
max_consensus_iter = 1000;  % 最大共识迭代次数
consensus_tolerance = 1e-4;  % 收敛容忍度

% =========================================================================
% 步骤3.1：通过通信图G计算Metropolis-Hastings权重矩阵W
% =========================================================================
N = Value_Params.N;
M = Value_Params.M;
K = 3;             % 三种类型


%% 第一步：计算局部信念Mass函数（基于个体观测数据）
for i = 1:Value_Params.N    
    for j = 1:Value_Params.M   
        total_obs = Value_data(i).observe(j,1) + Value_data(i).observe(j,2) + Value_data(i).observe(j,3);

        if total_obs > 0
            % 基于自己的观测次数计算信念概率：观测某类型次数/总观测次数
            % Value_data(i).initbelief(j,k) 表示智能体i认为任务j属于类型k的概率
            Value_data(i).initbelief(j,1) = Value_data(i).observe(j,1) / total_obs; % 任务j为类型1(价值300)的概率
            Value_data(i).initbelief(j,2) = Value_data(i).observe(j,2) / total_obs; % 任务j为类型2(价值500)的概率
            Value_data(i).initbelief(j,3) = Value_data(i).observe(j,3) / total_obs; % 任务j为类型3(价值1000)的概率
        else
            % 如果没有观测数据，保持原来不变（通常为初始的均匀分布）
            Value_data(i).initbelief(j,1:end) = Value_data(i).initbelief(j,1:end);
        end
    end
end


%% 第二步：计算共性函数（信念值的对数变换）
for i = 1:Value_Params.N    % i: 智能体索引 (1到N)，遍历所有智能体
    for j = 1:Value_Params.M    % j: 任务索引 (1到M)，遍历所有任务
        for k = 1:3    % k: 任务类型索引 (1到3)，对应三种可能的任务价值类型
            % =====================================================================
            % i, j, k 三重循环的详细含义：
            % =====================================================================
            % 例如：i=2, j=3, k=1 表示：
            % "智能体2对任务3为价值类型1(300)的信念进行对数变换"
            % =====================================================================
            % 对信念值取对数得到共性函数
            % Value_data(i).initbelief(j,k) 表示智能体i对任务j属于类型k的信念概率
            % 添加小常数避免log(0)的数值问题
            epsilon = 1e-10;
            Value_data(i).commonality(j,k) = log(Value_data(i).initbelief(j,k) + epsilon);
            % 结果：智能体i对任务j属于类型k的对数信念值（共性函数）
        end
    end
end


%% 第三步：线性共识算法


% 计算每个智能体的度数（邻居数量，包括自己）
degrees = sum(Graph, 2);  % 每行求和得到各智能体的度数

% 初始化权重矩阵W
W = zeros(N, N);

% 计算Metropolis-Hastings权重
for i = 1:N
    for j = 1:N
        if i == j
            % 对角线元素：自身权重 = 1 - 所有邻居权重之和
            % 先计算所有邻居权重，最后计算自身权重
            neighbor_weight_sum = 0;
            for k = 1:N
                if k ~= i && Graph(i,k) > 0  % k是i的邻居且k≠i
                    % Metropolis-Hastings权重公式：W(i,j) = 1/(1+max(deg(i),deg(j)))
                    W(i,k) = 1 / (1 + max(degrees(i), degrees(k)));
                    neighbor_weight_sum = neighbor_weight_sum + W(i,k);
                end
            end
            % 自身权重 = 1 - 邻居权重总和，确保每行权重之和为1
            W(i,i) = 1 - neighbor_weight_sum;
            
        elseif Graph(i,j) > 0  % i和j之间有通信连接
            % 邻居权重：使用Metropolis-Hastings公式
            % W(i,j) = 1/(1 + max(deg(i), deg(j)))
            % 这个公式确保了权重矩阵的双随机性质
            W(i,j) = 1 / (1 + max(degrees(i), degrees(j)));
        else
            % 没有连接的智能体之间权重为0
            W(i,j) = 0;
        end
    end
end


for consensus_iter = 1:max_consensus_iter

    %=========== 1. 把当前所有智能体的 commonality 拷贝出来，备用 ===========%
    % X_old: N × (M*K)，第 i 行是智能体 i 对所有任务、所有类型的 log 信念
    X_old = zeros(N, M*K);
    for i = 1:N
        tmp = Value_data(i).commonality;  % M × K
        X_old(i,:) = tmp(:)';             % 展平成一行
    end

    %=========== 2. 做一次线性共识：X = W * X_old ===========%
    X = W * X_old;   % W 是 N×N，每一列对应一个 (j,k) 的共识

    %=========== 3. 把更新后的 X 写回到 Value_data(i).commonality ===========%
    for i = 1:N
        tmp = reshape(X(i,:), [M, K]);    % 还原成 M × K
        Value_data(i).commonality = tmp;
    end

    %=========== 4. 检查收敛性：看本轮前后变化是否足够小 ===========%
    max_change = max(max(abs(X - X_old)));
    fprintf('共识第 %d 轮：max_change = %.6e\n', consensus_iter, max_change);

    if max_change < consensus_tolerance
        fprintf('共识算法在第 %d 次迭代后收敛\n', consensus_iter);
        break;
    end
end



% 显示初始状态（可选调试输出）
fprintf('开始线性共识算法，初始状态矩阵 X 的维度: %d × %d\n', size(X,1), size(X,2));

% =====================================================================================


%% 第四步：转换回信念值并归一化
for i = 1:Value_Params.N
    for j = 1:Value_Params.M
        for k = 1:3
            Value_data(i).initbelief(j,k) = exp(Value_data(i).commonality(j,k));
        end
        % 归一化信念值
        % 归一化这里先求个K
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
