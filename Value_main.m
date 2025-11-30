function [Value_data,Rcost,cost_sum,net_profit, initial_coalition]= Value_main(agents,tasks,Graph,Value_Params,AddPara)
% =========================================================================
% Value_main: 联盟形成的主计算函数
% =========================================================================

%% 第三步：计算Metropolis-Hastings权重矩阵

% 根据当前连接的拓扑图计算权重矩阵
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

% 初始化所有Value_data结构体、联盟结构、belief和观测矩阵
for i = 1:Value_Params.N
    % 基本信息初始化
    Value_data(i).agentID = agents(i).id;
    Value_data(i).agentIndex = i;
    Value_data(i).iteration = 0; % 联盟改变次数
    Value_data(i).unif = 0; % 均匀随机变量
    Value_data(i).coalitionstru = zeros(Value_Params.M+1, Value_Params.N);
    Value_data(i).initbelief = zeros(Value_Params.M+1, 3);
    
    % 将所有机器人放在空任务联盟中
    Value_data(i).coalitionstru(Value_Params.M+1, :) = [agents.id];
    
    % 初始化belief和观测矩阵
    for j = 1:Value_Params.M
        Value_data(i).initbelief(j, 1:end) = Value_Params.InitialBelief;
        for k = 1:Value_Params.K
            Value_data(i).observe(j, k) = 0;
            Value_data(i).preobserve(j, k) = 0;
        end
    end
end

% 初始化summatrix
summatrix = zeros(Value_Params.M, Value_Params.K);

%% 主要计算过程
for counter=1:50

    % 初始化并更新每个智能体（agent）在每轮迭代中的任务估计概率（prob）
    for i=1:Value_Params.N   
        for j=1:Value_Params.M
            Value_data(i).tasks(j).prob(counter,:)=Value_data(i).initbelief(j,1:end);
        end
    end
    
    T=1;   %迭代次数
    lastTime=T-1;
    doneflag=0;   %初始标志位0，收敛标志位为1
    
    while( doneflag==0)
        
        %所有agents选择自主任务
        for ii=1:Value_Params.N
            [incremental(ii),curnumberrow(ii),Value_data(ii)]=Value_order(agents, tasks, Value_data(ii), Value_Params);
            incremental(ii);
        end
        
        if (length(find(incremental==0))==Value_Params.N)
            lastTime= lastTime;
        else
            lastTime=T;
        end
        
        % 智能体之间通信
        Value_data=Value_communication(agents, tasks, Value_data, Value_Params,Graph);
        
        % 检查是否收敛
        if (T-lastTime>2) %连续两次迭代未改变联盟结构，认为收敛
            doneflag=1;
        else
            T=T+1; 
        end
    end
    
    if counter==1 %记录第一次联盟形成结构
        for j=1:Value_Params.M
            initial_coalition(j).member=find(Value_data(1).coalitionstru(j,:)~=0); % 记录联盟成员
        end
    end
    
    %% 根据形成的联盟实现智能体对当前任务的多次随机观测更新
    % 假设其他输入参数已经定义并初始化更新每个智能体的observe结构体
    % 对于所观测任务的三种类型的次数
    Value_data = updateObservations(Value_data, tasks, curnumberrow, agents, AddPara, Value_Params);

    %% 信息融合
    % 使用分布式共识算法进行信息融合
    Value_data = Info_fusion(Value_data, Graph, Value_Params,W);
    
    %% 计算联盟成本、收益和净利润
    % 初始化成本矩阵，行代表任务，列代表智能体
    Rcost = zeros(Value_Params.M, Value_Params.N);
    
    % 计算每个任务联盟的行动成本
    for j = 1:Value_Params.M
        % 找到任务 j 的联盟成员（非零位置对应的智能体ID）
        coalition(j).members = find(Value_data(1).coalitionstru(j,:) ~= 0);
        
        % 计算联盟中每个智能体到任务的距离成本
        for i = 1:length(coalition(j).members)
            agentIdx = coalition(j).members(i); % 智能体索引
            % 成本 = 欧氏距离 × 燃料单价
            Rcost(j,i) = sqrt((agents(agentIdx).x - tasks(j).x)^2 + ...
                             (agents(agentIdx).y - tasks(j).y)^2) * agents(agentIdx).fuel;
        end
    end
    
    % 计算当前轮次的总成本
    cost_sum(counter) = 0;
    for j = 1:size(Rcost,1)      % 遍历所有任务
        for i = 1:size(Rcost,2)  % 遍历所有智能体位置
            cost_sum(counter) = cost_sum(counter) + Rcost(j,i);
        end
    end
    
    % 计算当前轮次的总收益（所有任务价值之和）
    revenue_sum(counter) = 0;
    for j = 1:Value_Params.M
        revenue_sum(counter) = revenue_sum(counter) + tasks(j).value;
    end
    
    % 计算净利润 = 总收益 - 总成本
    net_profit(counter) = revenue_sum(counter) - cost_sum(counter);
    
    counter=counter+1;
    
end
end
