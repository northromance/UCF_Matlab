function [incremental,Value_data]=SA_Value_order(agents, tasks, Value_data, Value_Params)

incremental = 0; % 默认不改变联盟

% 备份当前联盟结构和相关状态，遍历候选任务时恢复使用
AValue_data.coalitionBackup = Value_data.coalitionstru; % 保存联盟矩阵副本（M+1 × N）
AValue_data.iterationBackup = Value_data.iteration;    % 保存迭代计数备份
AValue_data.unifBackup = Value_data.unif;              % 保存随机数备份

% 计算智能体所在的初始联盟
[curRow, curCol] = find(Value_data.coalitionstru == Value_data.agentID);

% 计算智能体所在的初始联盟
curMembers = find(Value_data.coalitionstru(curRow, :) ~= 0);

% -----------------------------------------------------------------
for j = 1:(Value_Params.M + 1)

    % 恢复联盟矩阵到备份，保证每次评估都是基于相同的初始联盟结构
    % 初始联盟结构
    Intial_coalitionstru = AValue_data.coalitionBackup;
    
    Value_data.coalitionstru = AValue_data.coalitionBackup;
    % 将智能体agentID从原来初始联盟中移除
    Value_data.coalitionstru(curRow, curCol) = 0;
    % 在j任务联盟中加入形成新的联盟结构
    Value_data.coalitionstru(j, Value_data.agentID) = Value_data.agentID;
    % 新联盟结构
    After_coalitionstru =  Value_data.coalitionstru;

    % 贪婪
    deltaU(j) = SA_greedy_utility(tasks, agents, Intial_coalitionstru, After_coalitionstru, Value_data.agentID, Value_Params, Value_data); 
end


[Max_deltaU, bestTask] = max(deltaU);

% -----------------------------------------------------------------
if Max_deltaU > 0
    % 更新联盟结构
    incremental = 1;
else

    % 计算接受概率
    Probability = exp(Max_deltaU / Value_Params.Temperature);

    % 有概率接受差的解
    if Probability > rand(1)
        % 接受较差解
        incremental = 1;
        Value_data.iteration = Value_data.iteration + 1; % 累计改变次数
    end
end


%% 根据 incremental 决定是否写入新的联盟结构
if incremental == 0
    % 未移动，恢复原始联盟矩阵备份
    Value_data.coalitionstru = AValue_data.coalitionBackup;
else
    % 移动：先恢复备份，再把原位置置0并在 bestTask 行上以相同列号放置 agentID
    Value_data.coalitionstru = AValue_data.coalitionBackup;
    Value_data.coalitionstru(curRow, curCol) = 0;
    Value_data.coalitionstru(bestTask, Value_data.agentID) = Value_data.agentID;
end


end
