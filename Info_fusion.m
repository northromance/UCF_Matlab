function [Value_data] = Info_fusion(Value_data, Graph, Value_Params,W)

% 共识参数设置
max_consensus_iter = 1000;  % 最大共识迭代次数
consensus_tolerance = 0.01;  % 收敛容忍度

% =========================================================================
% 步骤3.1：通过通信图G计算Metropolis-Hastings权重矩阵W
% =========================================================================
N = Value_Params.N;
M = Value_Params.M;
K = Value_Params.K;             % 三种任务类型


%% 第一步：计算局部信念Mass函数（基于个体观测数据）
for i = 1:Value_Params.N
    for j = 1:Value_Params.M
        % 计算对于任务类型j的观测次数
        total_obs = Value_data(i).observe(j,1) + Value_data(i).observe(j,2) + Value_data(i).observe(j,3);

        % 如果有观测数据
        if total_obs > 0
            % 基于自己的观测次数计算个体信念概率：个体观测某类型次数/总观测次数
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
% 每个智能体有一个j*k（6*3）的一个矩阵记录着对 每个任务的信念值的共性函数
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

for consensus_iter = 1:max_consensus_iter
    X_old = zeros(N, M*K);

    for i = 1:N
        tmp = Value_data(i).commonality;  % M × K

        % 确保展平的顺序是：任务1类型1, 任务1类型2, 任务2类型1, 任务2类型2, ...
        X_old(i,:) = reshape(tmp', 1, M*K);  % 展平并转置，确保按任务类型顺序展平
    end

    % 进行线性共识：X = W * X_old
    X = W * X_old;   % W 是 N×N，每一列对应一个 (j,k) 的共识

    %=========== 3. 把更新后的 X 写回到 Value_data(i).commonality ===========%
    for i = 1:N
        tmp = reshape(X(i,:),[K, M])';    % 还原成 M × K 矩阵
        Value_data(i).commonality = tmp;   % 更新智能体的 commonality
    end

    %=========== 4. 检查收敛性：看本轮前后变化是否足够小 ===========%
    % 计算 X 和 X_old 之间的变化
    diff_matrix = abs(X - X_old);  % 计算绝对差值矩阵
    max_change = max(max(diff_matrix));  % 计算最大的变化值

    % 查找最大变化值的索引
    [row, col] = find(diff_matrix == max_change);

    % 输出最大变化的元素及其位置
    fprintf('共识第 %d 轮：max_change = %.4f\n', consensus_iter, max_change);
    fprintf('最大变化元素的位置: X(%d, %d) 和 X_old(%d, %d)\n', row, col, row, col);
    fprintf('X中的变化元素值: %.4f\n', X(row, col));
    fprintf('X_old中的对应元素值: %.4f\n', X_old(row, col));
    fprintf('最大差值为: %.4f\n', X(row, col)-X_old(row, col));

    % 检查收敛性
    if max_change < consensus_tolerance
        fprintf('共识算法在第 %d 次迭代后收敛\n', consensus_iter);
        break;
    end
end
% =====================================================================================


%% 第四步：转换回信念值

% 计算组合共性函数
% 对应公式: Q(A) = exp(n * α_k(A))，恢复信念值
for i = 1:Value_Params.N  % 遍历所有智能体
    for j = 1:Value_Params.M  % 遍历所有任务
        for k = 1:Value_Params.K  % 遍历任务的三种类型（根据任务类型数量K）

            % 打印当前的 commonality(j,k) 值
            fprintf('智能体 %d, 任务 %d, 类型 %d 的原始 commonality 值: %.4f\n', i, j, k, Value_data(i).commonality(j,k));

            % 步骤 1: 从对数形式恢复信念值
            new_value = exp(Value_Params.N * Value_data(i).commonality(j,k));  % 转换回信念值

            % 打印计算后的结果
            fprintf('智能体 %d, 任务 %d, 类型 %d 计算后的信念值: %.4f\n', i, j, k, new_value);

            % 更新 commonality 值
            Value_data(i).commonality(j,k) = new_value;
        end
    end
end


% 计算未归一化质量函数
% m(ω_k) = (（-1）^0 )Q(ω_k)
for i = 1:Value_Params.N  % 遍历所有智能体
    for j = 1:Value_Params.M  % 遍历所有任务
        for k = 1:Value_Params.K+1 % 遍历任务的三种类型（根据任务类型数量K）
            % 步骤 1: 从对数形式恢复信念值
            if k ~=4
                % 计算未归一化质量函数
                Value_data(i).m_unnorm_mass(j,k) = Value_data(i).commonality(j,k);  % 转换回信念值
            else
                % 计算空集
                Value_data(i).m_unnorm_mass(j,k) = 1 - sum(Value_data(i).m_unnorm_mass(j,1:3));  % 转换回信念值
                % 计算K值K值应该是每个智能体对于每个任务有一个K
                Value_data(i).K(j,1) = 1/(1-Value_data(i).m_unnorm_mass(j,k));
            end
        end
    end
end


% 得到归一化Mass信念值
% K值应该是每个智能体对于每个任务有一个K
for i = 1:Value_Params.N  % 遍历所有智能体
    for j = 1:Value_Params.M  % 遍历所有任务
        for k = 1:Value_Params.K  % 遍历任务的三种类型（根据任务类型数量K）
            % 计算每个智能体的初始信念
            Value_data(i).initbelief(j,k) = Value_data(i).K(j,1) * Value_data(i).m_unnorm_mass(j,k);
        end
    end

    % 检查每个智能体信念之和是否为1
    for j = 1:Value_Params.M  % 遍历每个任务
        belief_sum = sum(Value_data(i).initbelief(j,:));  % 计算信念之和

        % 打印检查结果
        fprintf('\n[检查] 任务 %d 的信念之和 = %.12f (应接近 1.0)\n', j, belief_sum);

        if abs(belief_sum - 1) < 1e-9  % 如果信念和接近1
            fprintf('[检查结果] 和为1：OK\n\n');
        else  % 如果信念和不等于1
            fprintf('[检查结果] 和不为1：差值 = %.6e\n\n', belief_sum - 1);
        end
    end
end


end
