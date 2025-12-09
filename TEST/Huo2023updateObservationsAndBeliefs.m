function [Value_data] = Huo2023updateObservationsAndBeliefs(Value_data, tasks, agents, Value_Params, curnumberrow)
    % 更新观测矩阵并更新信念

    % 初始化summatrix
    summatrix = zeros(Value_Params.M, 3);

    % 记录一次联盟形成后观测次数
    for i = 1:Value_Params.N
        if curnumberrow(i) ~= Value_Params.M + 1
            for m = 1:20
                taskindex = find(tasks(curnumberrow(i)).value == tasks(curnumberrow(i)).WORLD.value);
                nontaskindex = find(tasks(curnumberrow(i)).value ~= tasks(curnumberrow(i)).WORLD.value);
                
                if rand <= agents(i).detprob
                    % 更新观测矩阵
                    Value_data(i).observe(curnumberrow(i), taskindex) = ...
                        Value_data(i).observe(curnumberrow(i), taskindex) + 1;
                    m = m + 1;
                elseif (agents(i).detprob < rand) && (rand <= (1 - 1/2 * agents(i).detprob))
                    % 更新观测矩阵
                    Value_data(i).observe(curnumberrow(i), nontaskindex(1)) = ...
                        Value_data(i).observe(curnumberrow(i), nontaskindex(1)) + 1;
                    m = m + 1;
                else
                    % 更新观测矩阵
                    Value_data(i).observe(curnumberrow(i), nontaskindex(2)) = ...
                        Value_data(i).observe(curnumberrow(i), nontaskindex(2)) + 1;
                    m = m + 1;
                end
            end
        end
    end

    % 计算观测矩阵的变化
    for j = 1:Value_Params.M
        for k = 1:3
            for i = 1:Value_Params.N
                summatrix(j, k) = summatrix(j, k) + Value_data(i).observe(j, k) - Value_data(i).preobserve(j, k);
            end
        end
    end

    % 更新每个智能体的预观测和观测矩阵
    for i = 1:Value_Params.N
        for j = 1:Value_Params.M
            for k = 1:3
                Value_data(i).preobserve(j, k) = summatrix(j, k);
                Value_data(i).observe(j, k) = summatrix(j, k);
            end
        end
    end

    % 一次联盟形成后根据观测更新belief
    for i = 1:Value_Params.N
        for j = 1:Value_Params.M
            Value_data(i).initbelief(j, :) = drchrnd([1 + Value_data(i).observe(j, 1), ...
                                                      1 + Value_data(i).observe(j, 2), ...
                                                      1 + Value_data(i).observe(j, 3)], 1)';
        end
    end

end
