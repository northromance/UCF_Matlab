function plotCoalitionUtility(Coalition_History, Value_data_History, agents, tasks, Value_Params)
% =========================================================================
% plotCoalitionUtility: 计算并绘制每轮联盟的总效用变化曲线
% 输入: Coalition_History-联盟历史, Value_data_History-每轮Value_data, agents-智能体信息,
%       tasks-任务信息, Value_Params-参数
% 输出: 联盟总效用变化图
% =========================================================================

rounds = length(Coalition_History);
net_profit = zeros(rounds,1);

% 计算每轮的净收益 = 任务总收益 - 智能体成本之和
for round = 1:rounds
    current_coalition = Coalition_History{round};
    if isempty(current_coalition)
        net_profit(round) = NaN;
        continue;
    end

    % 初始化每任务成本矩阵
    Rcost = zeros(Value_Params.M, Value_Params.N);

    % 计算每个任务的成员及其移动成本（距离*燃料）
    for j = 1:Value_Params.M
        members = find(current_coalition(j, :) ~= 0);
        for idx = 1:length(members)
            a = members(idx);
            Rcost(j, a) = sqrt((agents(a).x - tasks(j).x)^2 + (agents(a).y - tasks(j).y)^2) * agents(a).fuel;
        end
    end

    % 计算本轮成本和收入（仅统计有成员的任务收入）
    cost_sum = sum(Rcost(:));
    revenue_sum = 0;
    for j = 1:Value_Params.M
        members = find(current_coalition(j, :) ~= 0);
        if ~isempty(members)
            % 使用任务的标量价值
            revenue_sum = revenue_sum + tasks(j).value;
        end
    end

    net_profit(round) = revenue_sum - cost_sum;
end

% 绘制净收益曲线（忽略 NaN）
valid_idx = ~isnan(net_profit);
figure;
if any(valid_idx)
    plot(find(valid_idx), net_profit(valid_idx), 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
else
    plot(1:rounds, net_profit, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
end
xlabel('轮次 (Round)');
ylabel('净收益 (Net Profit)');
title('每轮联盟净收益变化');
grid on;

% 添加统计信息
fprintf('\n========== 联盟净收益统计 ==========%\n');
if any(valid_idx)
    fprintf('最大净收益: %.2f\n', max(net_profit(valid_idx)));
    fprintf('最小净收益: %.2f\n', min(net_profit(valid_idx)));
    fprintf('平均净收益: %.2f\n', mean(net_profit(valid_idx)));
    fprintf('最终净收益: %.2f\n', net_profit(find(valid_idx,1,'last')));
else
    fprintf('未记录有效轮次数据。\n');
end
fprintf('=====================================\n');

end