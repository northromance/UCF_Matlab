function [Value_data, Final_coalitionstru, Coalition_History, Value_data_History]= Value_main(agents,tasks,W,Value_Params,AddPara)
% =========================================================================
% Value_main: 联盟形成的主计算函数
% 输入: agents-智能体信息, tasks-任务信息, W-权重矩阵, Value_Params-参数结构体, AddPara-附加参数
% 输出: Value_data-智能体数据结构, Final_coalitionstru-最终联盟结构, Coalition_History-每轮联盟历史, Value_data_History-每轮Value_data历史
% =========================================================================

%% 初始化Value_data结构体和历史记录
Coalition_History = cell(50, 1);  % 存储每轮的联盟结构
Value_data_History = cell(50, 1); % 存储每轮的Value_data数据

for i = 1:Value_Params.N
    % 基本信息初始化
    Value_data(i).agentID = agents(i).id;
    Value_data(i).agentIndex = i;
    Value_data(i).iteration = 0;
    Value_data(i).unif = 0;
    Value_data(i).coalitionstru = zeros(Value_Params.M+1, Value_Params.N);
    Value_data(i).initbelief = zeros(Value_Params.M+1, 3);
    
    % 初始化为空任务联盟(M+1为虚空任务联盟)
    Value_data(i).coalitionstru(Value_Params.M+1, :) = [agents.id];
    Value_data(i).completionRate = agents(i).completionRate;
    
    % 初始化belief和观测矩阵
    for j = 1:Value_Params.M
        Value_data(i).initbelief(j, 1:end) = Value_Params.InitialBelief;
        for k = 1:Value_Params.K
            Value_data(i).observe(j, k) = 0;
            Value_data(i).preobserve(j, k) = 0;
        end
    end
end

%% 主计算循环：进行50次联盟形成及观测
for counter=1:50
    % 初始化智能体任务估计概率
    for i=1:Value_Params.N
        for j=1:Value_Params.M
            Value_data(i).tasks(j).prob(counter,:)=Value_data(i).initbelief(j,1:end);
        end
    end
    
    % 模拟退火参数初始化
    T = 1;
    doneflag = 0;
    k_stable = 0;

    % 记录初始联盟结构
    previous_coalitionstru = Value_data(1).coalitionstru;

    while(doneflag == 0)
        % 初始化增量数组，用来存储每个机器人的增量
        incremental = zeros(1, Value_Params.N);

        % 依次进行联盟结构计算
        for ii = 1:Value_Params.N
            % 调用SA_Value_order()进行联盟优化
            [incremental(ii), Value_data(ii)] = SA_Value_order(agents, tasks, Value_data(ii), Value_Params,counter,AddPara);
            
            % 传递联盟结构给下一个智能体
            if ii < Value_Params.N
                Value_data(ii + 1).coalitionstru = Value_data(ii).coalitionstru;
            end
        end

        % SA温度更新
        Value_Params.Temperature = Value_Params.alpha * Value_Params.Temperature;
        
        % 获取最终联盟结构
        final_coalitionstru = Value_data(Value_Params.N).coalitionstru;
        T = T + 1;
        
        % 收敛性检测
        if isequal(previous_coalitionstru, final_coalitionstru)
            k_stable = k_stable + 1;
        else
            k_stable = 0;
        end
        
        % 收敛判断：稳定迭代次数或温度达到阈值
        if k_stable >= Value_Params.max_stable_iterations || Value_Params.Temperature < Value_Params.Tmin
            disp('Convergence detected: Coalition structure has stabilized for multiple iterations.');
            doneflag = 1;
        end
        
        % 更新前次联盟结构
        previous_coalitionstru = final_coalitionstru;

        % 传递给其他机器人的联盟结构
        for ii = 1:Value_Params.N
            Value_data(ii).coalitionstru = final_coalitionstru;
        end
    end
    %% 智能体观测更新
    % 确定智能体任务分配
    curnumberrow = zeros(1, Value_Params.N);
    for i = 1:Value_Params.N
        [curRow, ~] = find(final_coalitionstru(:, i) == i);
        if ~isempty(curRow)
            curnumberrow(i) = curRow;
        else
            curnumberrow(i) = Value_Params.M + 1;  % 未分配任务
        end
    end
    
    % 调用updateObservations()更新观测数据
    Value_data = updateObservations(Value_data, tasks, curnumberrow, agents, AddPara, Value_Params);
    
    %% 信息融合
    % 调用Info_fusion()进行分布式共识
    Value_data = Info_fusion(Value_data, Value_Params,W);
    
    % 记录当前轮次的联盟结构和Value_data
    Coalition_History{counter} = final_coalitionstru;
    Value_data_History{counter} = Value_data;

end

%% 记录最终联盟结果
Final_coalitionstru = final_coalitionstru;

end
