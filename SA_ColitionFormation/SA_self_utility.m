function individual_utility = SA_self_utility(m, curRow, coalitionstru, agents, tasks, Value_Params, Value_data)
    % 计算个体在一个联盟中的效用
    % 给定联盟成员计算智能体在当前联盟的效用

    % 当前任务是
    % 当前计算的个体是m
    current_task =  curRow;
    %% 1. 判断当前智能体是否参与某个任务

    % 如果任务是空任务（即 curRow == Value_Params.M + 1），则效用为 0
    if current_task == Value_Params.M + 1
        individual_utility = 0; % 空任务效用为 0
        return;
    end
   
    %% 3. 计算联盟的效用 
    disp("当前任务为:" +current_task);

    b = Value_data.initbelief(current_task, :); % 获取智能体在当前任务的信念

    % 任务的WORLD值
    v = tasks(current_task).WORLD.value; 

    % 根据信念和任务价值计算收入
    revenue = v(1) * b(1) + v(2) * b(2) + v(3) * b(3);
    
    %% 4. 计算任务的成本
    % 计算智能体的成本，包括位置与燃料的成本
    cost_distance = sqrt((agents(m).x - tasks(current_task).x)^2 + (agents(m).y - tasks(current_task).y)^2) * agents(m).fuel;
    
    % 风险成本
    risk = tasks(current_task).WORLD.risk; % 三种类型的任务的风险值

    cost_risk = risk(1) * b(1) + risk(2) * b(2) + risk(3) * b(3); % 风险成本

    total_cost = cost_distance + cost_risk; % 总成本

    %% 计算个体效用

    coalition_member_num = length(find(coalitionstru(current_task,:) ~=0));
    
    % 5. 计算智能体的效用：效用 = 收入 - 成本（确保效用非负）
    individual_utility = revenue/coalition_member_num - total_cost; % 效用不能为负，取最大值
end
