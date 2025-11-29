% 设置参数
%% 测试 线性共识算法 中Mass函数的融合逻辑

N = 3;  % 智能体数量
M = 2;  % 任务数量
K = 2;  % 任务类型数量
max_consensus_iter = 10;  % 最大共识迭代次数
consensus_tolerance = 1e-5;  % 收敛容忍度

% 初始化信念数据 (commonality)
% 每个智能体对每个任务和任务类型的信念（M×K）
Value_data(1).commonality = [
    -1.1, -1.2;  % 任务1类型1, 任务1类型2
    -1.3, -1.4   % 任务2类型1, 任务2类型2
];

Value_data(2).commonality = [
    -0.9, -1.0;
    -1.1, -1.2
];

Value_data(3).commonality = [
    -1.0, -1.1;
    -1.2, -1.3
];

% 初始化共识矩阵 W (N×N)
W = [
    0.5, 0.25, 0.25;
    0.25, 0.5, 0.25;
    0.25, 0.25, 0.5
];

% 初始 X_old
X_old = zeros(N, M * K);  % N×(M*K)

% 共识迭代过程
for consensus_iter = 1:max_consensus_iter
    %=========== 1. 拷贝当前所有智能体的 commonality，备用 ===========%
    % X_old: N × (M*K)，第 i 行是智能体 i 对所有任务、所有类型的 log 信念
    for i = 1:N
        tmp = Value_data(i).commonality;  % M × K

        % 确保展平的顺序是：任务1类型1, 任务1类型2, 任务2类型1, 任务2类型2
        X_old(i,:) = reshape(tmp', 1, M * K);  % 展平成一维向量
    end

    %=========== 2. 做一次线性共识：X = W * X_old ===========%
    X = W * X_old;  % W 是 N×N，每一列对应一个 (j,k) 的共识

    %=========== 3. 把更新后的 X 写回到 Value_data(i).commonality ===========%
    for i = 1:N
        % 将更新后的 X 展平后的向量恢复成 M × K 矩阵
        tmp = reshape(X(i,:), [K, M])';    % 恢复成 M × K 矩阵
        Value_data(i).commonality = tmp;   % 更新智能体的 commonality
    end

    %=========== 4. 检查收敛性：看本轮前后变化是否足够小 ===========%
    max_change = max(max(abs(X - X_old)));  % 计算前后信念的最大变化
    fprintf('共识第 %d 轮：max_change = %.6e\n', consensus_iter, max_change);

    % 如果变化小于容忍度，认为已收敛
    if max_change < consensus_tolerance
        fprintf('共识算法在第 %d 次迭代后收敛\n', consensus_iter);
        break;
    end
end
