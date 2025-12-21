function [incremental, Value_data] = SA_Value_order(agents, tasks, Value_data, Value_Params,counter,AddPara)
% =========================================================================
% SA_Value_order: 基于模拟退火的联盟结构优化
% 输入: agents-智能体信息, tasks-任务信息, Value_data-智能体数据, Value_Params-参数
% 输出: incremental-是否改变联盟(0/1), Value_data-更新后的智能体数据
% =========================================================================

incremental = 0;

%% 备份当前状态
backup.coalition = Value_data.coalitionstru;
backup.iteration = Value_data.iteration;
backup.unif = Value_data.unif;

%% 获取当前智能体位置
[currentRow, currentCol] = find(Value_data.coalitionstru == Value_data.agentID);

%% 评估所有可能的任务联盟
Delta_U = zeros(1, Value_Params.M + 1);
for j = 1:(Value_Params.M + 1)
    % 构造候选联盟结构
    initial_coalition = backup.coalition;
    candidate_coalition = backup.coalition;
    
    % 从原联盟移除智能体
    candidate_coalition(currentRow, currentCol) = 0;
    % 加入新任务联盟
    candidate_coalition(j, Value_data.agentID) = Value_data.agentID;
    
    if AddPara.control_algorithm == 1
    % 计算效用变化
    Delta_U(j) = SA_greedy_utility(tasks, agents, initial_coalition, candidate_coalition, ...
                                  Value_data.agentID, Value_Params, Value_data);
    elseif AddPara.control_algorithm == 2
    % 
    Delta_U(j) = SA_altruistic_utility(tasks, agents, initial_coalition, candidate_coalition, ...
                                  Value_data.agentID, Value_Params, Value_data);
    elseif AddPara.control_algorithm == 3
    Delta_U(j) = SA_goalbal_utility(tasks, agents, initial_coalition, candidate_coalition, ...
                                  Value_data.agentID, Value_Params, Value_data);
    end

end

%% 模拟退火决策
% 获取最大效用增益差值及对应任务
[maxDelta_U, bestTask] = max(Delta_U);

if maxDelta_U > 0
    % 接受更优解
    incremental = 1;
else
    % SA概率接受机制
    acceptProb = exp( maxDelta_U / Value_Params.Temperature);
    if acceptProb > rand()
        incremental = 1;
        Value_data.iteration = Value_data.iteration + 1;
    end
end

%     [maxDelta_U, bestTask] = max(Delta_U);  % 获取效用增益最大的位置

% if currentRow == Value_Params.M + 1 && counter == 1% 判断当前机器人是否处于虚空任务联盟
%     % 如果是虚空任务联盟，直接加入效用增益最大的联盟
%     [maxDelta_U, bestTask] = max(Delta_U(Delta_U ~= 0));  % 获取效用增益最大的位置
%     incremental = 1;  % 直接接受该联盟

% elseif counter > 1
%     if maxDelta_U > 0
%         % 接受更优解
%         incremental = 1;
%     else
%         % SA概率接受机制
%         acceptProb = exp(maxDelta_U / Value_Params.Temperature);
%         if acceptProb > rand()
%             incremental = 1;
%             Value_data.iteration = Value_data.iteration + 1;
%         end
%     end
% end



%% 更新联盟结构
if incremental == 0
    % 保持原联盟
    Value_data.coalitionstru = backup.coalition;
else
    % 执行联盟变更
    Value_data.coalitionstru = backup.coalition;
    Value_data.coalitionstru(currentRow, currentCol) = 0;
    Value_data.coalitionstru(bestTask, Value_data.agentID) = Value_data.agentID;
end

end
