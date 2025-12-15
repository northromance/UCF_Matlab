function deltaU = SA_greedy_utility(tasks, agents, Intial_coalitionstru, After_coalitionstru, agentID, Value_Params, Value_data)
    % 输入：
    % Intial_coalitionstru: 初始联盟结构矩阵（源联盟）
    % After_coalitionstru: 更新后的联盟结构矩阵（目标联盟）
    % agentID: 智能体的ID
    % agents: 所有智能体的相关信息（如位置，燃料等）
    % tasks: 所有任务的信息（如位置，风险等）

    % 计算智能体所在的初始任务（行索引）
    % 找到智能体在初始联盟结构矩阵中的位置
    [curRow, curCol] = find(Intial_coalitionstru == agentID); % 查找智能体原来的位置
    

    [After_curRow, After_curCol] = find(After_coalitionstru == agentID); % 查找智能体移动后的位置
    
    % 当前智能体所在的初始任务行号
    curRow = curRow(1); % 可能有多个匹配，取第一个（通常只有一个）
    After_curRow = After_curRow(1); % 移动后的任务行号

    % 初始化各个效用变量
    % source_before = 0; % 源联盟中智能体移除前的效用总和
    % source_after = 0; % 源联盟中智能体移除后的效用总和
    % target_before = 0; % 目标联盟中不包含智能体前的效用总和
    % target_after = 0; % 目标联盟中包含智能体后的效用总和
    % 
    % % 查找源联盟中该任务行的所有成员（当前任务行 curRow）
    % source_members = find(Intial_coalitionstru(curRow, :) ~= 0); 
    % 
    % % 查找目标联盟中该任务行的所有成员（移动后的任务行 After_curRow）
    % target_members = find(After_coalitionstru(After_curRow, :) ~= 0); 


    % 计算初始联盟结构中源联盟的全部成员的效用和
    % 遍历源联盟的所有成员，计算每个成员的效用，并加总到 source_before
    m = agentID;
    
    source_self_utility = SA_self_utility(m, curRow, Intial_coalitionstru, agents, tasks, Value_Params, Value_data); % 计算每个成员的效用并加总
    % 计算目标联盟中添加智能体之后的效用（target_after）
    % 遍历更新后的目标联盟，计算所有任务行中的效用，并加总


    obj_self_utility = SA_self_utility(m, After_curRow, After_coalitionstru, agents, tasks, Value_Params, Value_data); % 计算每个成员的效用并加总


    deltaU = obj_self_utility -  source_self_utility;


end
