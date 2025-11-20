function [Value_data,Rcost,cost_sum,net_profit, initial_coalition]= Value_main(agents,tasks,Graph,Value_Params,AddPara)
% =========================================================================
%  函数名称：Value_main
%
%  算法主要功能：
%  ------------------------------------------------------------------------
%  本算法基于多智能体联盟形成（Coalition Formation）与任务值估计机制，
%  完成以下核心流程：
%    1. 初始化 agent 的 belief、联盟结构和观测矩阵。
%    2. 通过迭代过程：每个 agent 根据 belief 选择任务并形成联盟。
%    3. 按通信拓扑 Graph 执行邻居信息共享，更新任务估计。
%    4. 每轮联盟形成后，agent 通过模拟观测更新 Dirichlet belief。
%    5. 计算每轮联盟结构下的成本、收益与净收益。
%    6. 重复多次（counter=1:50），用于统计不同联盟的收益表现。
%
%  输入参数：
%  ------------------------------------------------------------------------
%  agents：结构体数组，包含：
%       - id：agent ID
%       - x, y：空间坐标
%       - fuel：燃料单价（决定行动成本）
%       - detprob：观测正确概率
%
%  tasks：结构体数组，包含：
%       - x, y：任务位置
%       - value：任务当前可能值（一个 3 维向量）
%       - WORLD.value：任务真实值（环境设定）
%
%  Graph：通信邻接矩阵（N×N），Graph(i,j)=1 表示 agent i 和 j 可通信
%
%
%  输出参数：
%  ------------------------------------------------------------------------
%  Value_data：包含每个 agent 在各轮迭代中的 belief、观测、联盟结构等信息
%
%  Rcost：联盟中 agent 的行动成本（距离 × fuel）
%
%  cost_sum：50 次联盟形成中，每次的总成本
%
%  net_profit：50 次联盟形成中，每次的（收益 - 成本）
%
%  initial_coalition：第一次联盟形成的联盟成员结构
%
%  注：算法内部会运行多轮 belief 更新、联盟优化和通信，最终输出每轮的成本与收益。
%
% =========================================================================

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

    % 这部分代码的功能是初始化并更新每个智能体（agent）在每轮迭代中的任务估计概率（prob）
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
    for i = 1:Value_Params.N
        % 遍历每个智能体 i，N 是智能体总数
        
        if curnumberrow(i) ~= Value_Params.M+1
            % 判断智能体 i 当前所在任务行号是否不是空任务行（M+1 代表空任务）
            % 如果是空任务，则跳过
            
            for m = 1:AddPara.NumObs
                % 每个智能体在该任务上执行 20 次观测尝试
                
                % 找到当前任务行中正确子任务的索引
                taskindex = find(tasks(curnumberrow(i)).value == tasks(curnumberrow(i)).WORLD.value);
                
                % 找到当前任务行中错误/非目标子任务的索引
                nontaskindex = find(tasks(curnumberrow(i)).value ~= tasks(curnumberrow(i)).WORLD.value);
                
                if rand <= agents(i).detprob
                    % 生成随机数，如果小于等于智能体检测概率 detprob
                    % 表示智能体成功检测到正确任务
                    Value_data(i).observe(curnumberrow(i), taskindex) = ...
                        Value_data(i).observe(curnumberrow(i), taskindex) + 1;
                    % 对智能体 i 的观测矩阵 observe，在当前任务行 taskindex 上加 1
                    
                    m = m + 1;
                    % 计数器 m 增加（可选，因为 for 循环会自动加 1）
                    
                elseif (agents(i).detprob < rand) && (rand <= (1 - 1/2*agents(i).detprob))
                    % 如果随机数大于 detprob 且小于等于 (1 - detprob/2)
                    % 表示智能体观察到了错误的第一个非目标任务
                    Value_data(i).observe(curnumberrow(i), nontaskindex(1)) = ...
                        Value_data(i).observe(curnumberrow(i), nontaskindex(1)) + 1;
                    % 对 observe 矩阵在错误任务索引 nontaskindex(1) 上加 1
                    
                    m = m + 1;
                    % 计数器增加
                    
                else
                    % 剩余情况：智能体观察到了错误的第二个非目标任务
                    Value_data(i).observe(curnumberrow(i), nontaskindex(2)) = ...
                        Value_data(i).observe(curnumberrow(i), nontaskindex(2)) + 1;
                    % 对 observe 矩阵在错误任务索引 nontaskindex(2) 上加 1
                    
                    m = m + 1;
                    % 计数器增加
                end
            end
        end
    end

    %% 综合所有智能体信息观测矩阵
    for j=1:Value_Params.M
        for k=1:3
            for i=1:Value_Params.N
                summatrix(j,k)=summatrix(j,k)+ Value_data(i).observe(j,  k)-Value_data(i).preobserve(j,  k);
            end
        end
    end
    
    for i=1:Value_Params.N
        for j=1:Value_Params.M
            for k=1:3
                Value_data(i).preobserve(j,k)= summatrix(j,k);
                Value_data(i).observe(j,  k)= summatrix(j,k);
            end
        end
    end

    %% 根据联盟形成后的结果更新信念
    % for i=1:Value_Params.N
    %     for j=1:Value_Params.M
    %         Value_data(i).initbelief(j,1:end)=drchrnd([1+Value_data(i).observe(j,1),1+Value_data(i).observe(j,2),1+Value_data(i).observe(j,3)],1)';
    %         %  Value_data(i).initbelief(j,1:end)=[1/3,1/3,1/3];
    %     end
    % end
    

    %% 信息融合
    % 计算每个机器人上的共性函数

    % 局部更新对所有任务的共性函数矩阵

    % 根据每个节点的连接拓扑根据Metropolis-Hastings算法得到权重矩阵

    % 通过线性共识算法更新状态矩阵

    % 每个机器人反推得到一致的信念

    % 再进行联盟形成
    

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
