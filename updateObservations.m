function [Value_data] = updateObservations(Value_data, tasks, curnumberrow, agents, AddPara, Value_Params)
    % updateObservations 更新每个智能体的观测数据
    % 输入参数：
    %   Value_data - 存储智能体观测数据的结构体
    %   tasks - 任务数组，包含任务的实际值与目标值
    %   curnumberrow - 每个智能体当前任务的行号
    %   agents - 存储智能体信息（包括检测概率等）的结构体
    %   AddPara - 额外参数结构体（例如观测次数）
    %   Value_Params - 包含智能体总数 N 和任务数量 M 的结构体
    % 输出：
    %   更新后的 Value_data 结构体
    
    %%  判断逻辑是如果随机数小于detprob 则检测出正确的任务类型 
    % 输出是Value_data.observe对于分配的任务curnumberrow(i)所观测到的三种任务类型的次数
    
    %% 判断逻辑
    % rand <= agents(i).detprob
    % (agents(i).detprob < rand) && (rand <= (1 - 1/2*agents(i).detprob))
    % else


    % 遍历每个智能体
    for i = 1:Value_Params.N
        % 判断该智能体是否有被分配任务
        if curnumberrow(i) ~= Value_Params.M+1
            % 如果智能体被分配任务，则进行观测

            for m = 1:AddPara.NumObs
                % 每个智能体在该任务上执行多次观测（AddPara.NumObs为观测次数）
                
                % 找到智能体分配的任务对应的目标任务索引
                taskindex = find(tasks(curnumberrow(i)).value == tasks(curnumberrow(i)).WORLD.value);
                
                % 找到当前任务行中错误/非目标任务的索引
                nontaskindex = find(tasks(curnumberrow(i)).value ~= tasks(curnumberrow(i)).WORLD.value);
                
                % 判断智能体是否检测到目标任务
                if rand <= agents(i).detprob
                    % 生成随机数，若小于等于智能体的检测概率，说明智能体检测到了目标任务
                    Value_data(i).observe(curnumberrow(i), taskindex) =  Value_data(i).observe(curnumberrow(i), taskindex) + 1;
                    % 更新观测矩阵，增加对目标任务的观测次数
                    
                elseif (agents(i).detprob < rand) && (rand <= (1 - 1/2*agents(i).detprob))
                    % 如果随机数大于 detprob 且小于等于 (1 - detprob/2)，说明智能体观察到了一个非目标任务
                    Value_data(i).observe(curnumberrow(i), nontaskindex(1)) =  Value_data(i).observe(curnumberrow(i), nontaskindex(1)) + 1;
                    % 更新观测矩阵，增加对第一个非目标任务的观测次数
                    
                else
                    % 如果随机数大于 (1 - detprob/2)，说明智能体观察到了第二个非目标任务
                    Value_data(i).observe(curnumberrow(i), nontaskindex(2)) =  Value_data(i).observe(curnumberrow(i), nontaskindex(2)) + 1;
                    % 更新观测矩阵，增加对第二个非目标任务的观测次数
                end
            end
        end
    end
end
