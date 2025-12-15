function [incremental,curRow,Value_data]=Huo_Value_order(agents, tasks, Value_data, Value_Params)
% Huo_Value_order: 智能体基于效用选择或离开联盟的决策函数
%
% 输入：
%   - agents: 智能体数组，包含位置信息、燃料等属性
%   - tasks: 任务数组，包含任务位置信息、价值等
%   - Value_data: 单个智能体的状态结构体（包含 coalitionstru, agentID, initbelief 等）
%   - Value_Params: 参数结构体（包含 M:任务数量, K:类型数 等）
%
% 输出：
%   - incremental: 二值标志，1 表示该智能体改变了联盟，0 表示未改变
%   - curRow: 该智能体当前所在的任务行号（任务索引）
%   - Value_data: 可能被修改的智能体状态（包括 coalitionstru 和 iteration）
%
% 说明：
%   - 该函数实现单个智能体尝试从当前任务离开并加入某个候选任务（包括空任务）的策略。
%   - 通过计算当前效用 curUtil 与每个候选任务的候选效用 candUtil，选择令效用最大的转移。
%   - 为了避免在遍历候选任务时破坏原始联盟结构，函数内部会使用备份 AValue_data.coalitionBackup。

% -------------------- 变量说明（本函数局部） --------------------
% incremental: 标志位，若智能体最终选择移动则为1，否则为0
% curRow, curCol: 在 coalitionstru 中表示该智能体当前的位置 (row: 任务索引, col: 某个位置列)
% curMembers: 当前任务行上所有非零成员（该任务的联盟成员）
% curUtil: 智能体在当前任务中的效用（通过 Value_utility 计算）
% candUtil: 候选任务效用数组，长度为 M+1（包括空任务索引 M+1）
% bestTask: 使效用最大的任务索引
% -----------------------------------------------------------------

incremental = 0; % 默认不改变联盟

% 备份当前联盟结构和相关状态，遍历候选任务时恢复使用
AValue_data.coalitionBackup = Value_data.coalitionstru; % 保存联盟矩阵副本（M+1 × N）
AValue_data.iterationBackup = Value_data.iteration;    % 保存迭代计数备份
AValue_data.unifBackup = Value_data.unif;              % 保存随机数备份

% -----------------------------------------------------------------
% 找出当前智能体在自己认为的联盟结构中的未知，即被分配给了第几个任务
% Value_data.coalitionstru 是 (M+1)×N 的矩阵，行1..M表示任务1..M，行M+1表示空任务
% 每一列代表一个智能体在对应任务/空任务位置的占位（非零表示该智能体在该行）
[curRow, curCol] = find(Value_data.coalitionstru == Value_data.agentID);
% curRow: 当前任务索引（1..M 或 M+1），curCol: 在矩阵中的列索引

% 当前任务的所有成员（列索引），用于计算当前效用
curMembers = find(Value_data.coalitionstru(curRow, :) ~= 0);

% 计算智能体在当前任务位置的效用（由外部函数 Value_utility 给出）
curUtil = Value_utility(agents, tasks, curRow, curCol, curMembers, Value_data, Value_Params);

% -----------------------------------------------------------------
% 遍历所有候选任务（包括空任务行 M+1），计算加入该任务后智能体的候选效用
% 注意：计算任务的时候先将智能体从当前任务的矩阵中移除
% 在遍历每个候选任务时，需要先把联盟矩阵恢复为备份状态，
% 然后把当前智能体从原位置置0，再尝试把智能体放入候选任务的对应列上。
%
% -----------------------------------------------------------------
for j = 1:(Value_Params.M + 1)

    % 恢复联盟矩阵到备份，保证每次评估都是基于相同的初始联盟结构
    Value_data.coalitionstru = AValue_data.coalitionBackup;

    % 将智能体从当前位置移除（防止重复计入）
    Value_data.coalitionstru(curRow, curCol) = 0;

    % 将智能体agentID临时放入候选任务 j 的对应列位置（使用 agentID 作为占位）
    Value_data.coalitionstru(j, Value_data.agentID) = Value_data.agentID;

    % 计算候选联盟的成员列表（非零列索引）
    candMembers = find(Value_data.coalitionstru(j, :) ~= 0);

    % 计算智能体加入该候选任务后的效用
    % 计算加入后
   
    candUtil(j) = Value_utility(agents, tasks, j, Value_data.agentID, candMembers, Value_data, Value_Params);
    % 注意：此处使用 Value_data.agentID 作为 col 参数传入，Value_utility 需要能接受该索引含义
end

% 找到使效用最大的候选任务和对应效用值
[maxUtil, bestTask] = max(candUtil);
% 如果需要查看多个最优候选，可使用 sort(candUtil,'descend') 获取候选序列

% -----------------------------------------------------------------
% 决策逻辑：
% - 若 maxUtil == 0：表示所有候选任务的效用均为0，智能体选择进入空任务（回到空任务行）
% - 否则若 maxUtil > curUtil：表示存在使效用增加的移动，智能体选择移动（incremental=1）
%   并更新 iteration 计数与随机变量 unif
% - 否则不移动
% -----------------------------------------------------------------
if maxUtil == 0
    % 所有候选都没有正的收益，回到空任务位置（把当前位置清空并放到空任务行）
    Value_data.coalitionstru = AValue_data.coalitionBackup;
    Value_data.coalitionstru(curRow, curCol) = 0;
    Value_data.coalitionstru(Value_Params.M + 1, curCol) = Value_data.agentID;
else
    if maxUtil > curUtil
        % 发现更优的任务，标记为已改变联盟
        incremental = 1;
        Value_data.iteration = Value_data.iteration + 1; % 累计改变次数
        Value_data.unif = rand(1); % 更新随机数（用于随机化决策或打破平局）
    end
end

% 最终根据 incremental 决定是否写入新的联盟结构
if incremental == 0
    % 未移动，恢复原始联盟矩阵备份
    Value_data.coalitionstru = AValue_data.coalitionBackup;
else
    % 移动：先恢复备份，再把原位置置0并在 bestTask 行上以相同列号放置 agentID
    Value_data.coalitionstru = AValue_data.coalitionBackup;
    Value_data.coalitionstru(curRow, curCol) = 0;
    Value_data.coalitionstru(bestTask, curCol) = Value_data.agentID;
end

end
