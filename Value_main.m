function [Value_data,Rcost,cost_sum,net_profit, initial_coalition]= Value_main(agents,tasks,W,Value_Params,AddPara)
% =========================================================================
% Value_main: 联盟形成的主计算函数
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

    % 将所有机器人放在空任务联盟中Value_Params.M+1为虚空任务联盟
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

%% 主要计算过程
% counter 为进行50次联盟形成及观测
for counter=1:50
    % 初始化并更新每个智能体（agent）在每轮迭代中的任务估计概率（prob）
    for i=1:Value_Params.N
        for j=1:Value_Params.M
            Value_data(i).tasks(j).prob(counter,:)=Value_data(i).initbelief(j,1:end);
        end
    end


    T=1;   % 初始化迭代次数
    doneflag=0; % 收敛收敛标志位为1
    k_stable = 0;  % 初始化稳定轮数计数器

    % 记录初始联盟结构
    previous_coalitionstru = Value_data(1).coalitionstru;

    while(doneflag == 0)
        % 初始化增量数组，用来存储每个机器人的增量
        incremental = zeros(1, Value_Params.N);

        % 依次进行联盟结构的计算
        for ii = 1:Value_Params.N
            % 第一个计算完联盟结构后，记录当前联盟结构结果，传给下一个机器人
            [incremental(ii), Value_data(ii)] = SA_Value_order(agents, tasks, Value_data(ii), Value_Params);

            % 将当前机器人计算得到的联盟结构传递给下一个机器人
            if ii < Value_Params.N
                % 将当前机器人 ii 的联盟结构传递给下一个机器人 ii+1
                Value_data(ii + 1).coalitionstru = Value_data(ii).coalitionstru;
            end

        end

        % 更新温度（模拟退火的一部分）
        Value_Params.Temperature = Value_Params.alpha * Value_Params.Temperature;

        % 记录最后一个机器人的联盟结构为最终联盟结构
        final_coalitionstru = Value_data(Value_Params.N).coalitionstru;

        % 迭代次数加1
        T = T+1;

        % 判断是否联盟结构在多轮迭代后都没有发生变化
        if isequal(previous_coalitionstru, final_coalitionstru)
            % 如果联盟结构没有变化
            k_stable = k_stable + 1;  % 增加稳定轮数
        else
            % 如果联盟结构发生了变化，更新previous_coalitionstru
            k_stable = 0;  % 重置稳定轮数
        end

        % 判断是否连续多轮联盟结构没有变化，认为收敛
        if k_stable >= Value_Params.max_stable_iterations || Value_Params.Temperature < Value_Params.Tmin
            disp('Convergence detected: Coalition structure has stabilized for multiple iterations.');
            doneflag = 1;  % 设置doneflag为1，结束循环
        end

        % 将当前最后联盟结构作为下一次的之前联盟结构
        previous_coalitionstru = final_coalitionstru;  % 更新为当前联盟结构

        % 传递给其他机器人的联盟结构
        for ii = 1:Value_Params.N
            Value_data(ii).coalitionstru = final_coalitionstru;
        end
    end
    %% 根据形成的联盟实现智能体对当前任务的多次随机观测更新
    % 初始化 curnumberrow，大小为智能体的数量
    curnumberrow = zeros(1, Value_Params.N);  % 初始化每个智能体被分配的任务行号
    for i = 1:Value_Params.N    % 遍历每个智能体
        % 使用find函数查找任务分配给智能体i的位置
        [curRow, ~] = find(final_coalitionstru(:, i) == i);  % 查找智能体i在final_coalitionstru中分配到的任务

        if ~isempty(curRow)  % 如果找到了任务
            curnumberrow(i) = curRow;  % 将智能体i分配的任务行号赋值给curnumberrow
        else
            curnumberrow(i) = Value_Params.M + 1;  % 如果没有分配任务，赋值为M+1
        end
    end
    % 更新 Value_data的 observe

    Value_data = updateObservations(Value_data, tasks, curnumberrow, agents, AddPara, Value_Params);

    %% 信息融合

    % 使用分布式共识算法进行信息融合
    Value_data = Info_fusion(Value_data, Value_Params,W);

    counter = counter + 1;

end


end
