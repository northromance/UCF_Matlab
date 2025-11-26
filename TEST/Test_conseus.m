clear; clc;

%% 参数设置
N = 5;          % 智能体数量
M = 4;          % 任务数量
K = 3;          % 任务类型数（比如三种类型）

% 构造一个行随机矩阵 W（每行和为 1），模拟共识权重矩阵
A = rand(N);                     % 任意随机非负矩阵
W = A ./ sum(A, 2);              % 按行归一化，保证 sum_j W(i,j) = 1

%% 初始化 Value_data.commonality
% Value_data(i).commonality(j,k) 表示：
% 智能体 i 对任务 j 类型 k 的 log 信念（这里只是随机数，用来测试）
Value_data_A = struct();
for i = 1:N
    Value_data_A(i).commonality = rand(M, K);  % 随机初始化
end

% 拷贝一份，用于矩阵版本
Value_data_B = Value_data_A;

%% 实现方式一：三重循环版本（按 j,k 提取向量 x 再做 W * x）

for j = 1:M
    for k = 1:K
        % 取出当前任务 j、类型 k 下，所有智能体的 commonality 向量 x (N×1)
        x = zeros(N,1);
        for i = 1:N
            x(i) = Value_data_A(i).commonality(j,k);
        end

        % 共识一次：x_new = W * x
        x_new = W * x;

        % 写回到结构体中
        for i = 1:N
            Value_data_A(i).commonality(j,k) = x_new(i);
        end
    end
end

%% 实现方式二：矩阵版本（一次性展开所有 (j,k)）

% 1. 把当前所有智能体的 commonality 拷贝出来，组成大矩阵 X_old (N × (M*K))
X_old = zeros(N, M * K);
for i = 1:N
    tmp = Value_data_B(i).commonality;  % M × K
    X_old(i,:) = tmp(:)';              % 展平成 1 × (M*K)
end

% 2. 一次性做共识：对每一列（一个固定的 (j,k)），都做 W * 那列
X = W * X_old;                         % 结果仍是 N × (M*K)

% 3. 把 X 写回到 Value_data_B(i).commonality
for i = 1:N
    tmp = reshape(X(i,:), [M, K]);     % 还原成 M × K
    Value_data_B(i).commonality = tmp;
end

%% 比较两种实现结果

max_diff = 0;
for i = 1:N
    diff_i = abs(Value_data_A(i).commonality - Value_data_B(i).commonality);
    max_diff = max(max_diff, max(diff_i(:)));
end

fprintf('最大差异 = %.12e\n', max_diff);
if max_diff < 1e-12
    fprintf('两种实现结果完全一致（在数值精度范围内）。\n');
else
    fprintf('两种实现存在差异，请检查实现。\n');
end
