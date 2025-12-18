function deltaU = SA_greedy_utility(tasks, agents, initial_coalition, target_coalition, agentID, Value_Params, Value_data)
% =========================================================================
% SA_greedy_utility: 计算智能体联盟变更的效用差值
% 输入: tasks-任务信息, agents-智能体信息, initial_coalition-初始联盟, 
%       target_coalition-目标联盟, agentID-智能体ID, Value_Params-参数, Value_data-数据
% 输出: deltaU-效用变化值
% =========================================================================

%% 获取智能体在联盟中的位置
[initialRow, ~] = find(initial_coalition == agentID);
[targetRow, ~] = find(target_coalition == agentID);

% 取第一个匹配位置
initialRow = initialRow(1);
targetRow = targetRow(1);

%% 计算效用变化
% 初始联盟中的自身效用
initialUtility = SA_self_utility(agentID, initialRow, initial_coalition, agents, tasks, Value_Params, Value_data);

% 目标联盟中的自身效用
targetUtility = SA_self_utility(agentID, targetRow, target_coalition, agents, tasks, Value_Params, Value_data);

% 计算效用差值
deltaU = targetUtility - initialUtility;

end
