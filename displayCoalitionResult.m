function displayCoalitionResult(final_coalition, Value_Params)
% =========================================================================
% displayCoalitionResult: 显示和分析最终联盟结构
% 输入: final_coalition-最终联盟结构矩阵, Value_Params-参数结构体
% 输出: 格式化输出联盟分配结果
% =========================================================================

% 显示最终联盟结构
fprintf('\n========== 最终联盟结构 ==========\n');
fprintf('联盟矩阵 (%d×%d):\n', size(final_coalition, 1), size(final_coalition, 2));
disp(final_coalition);

% 分析联盟分配情况
fprintf('\n智能体任务分配情况:\n');
for i = 1:Value_Params.N
    [assignedTask, ~] = find(final_coalition(:, i) == i);
    if ~isempty(assignedTask)
        if assignedTask == Value_Params.M + 1
            fprintf('智能体 %d: 未分配任务 (空联盟)\n', i);
        else
            fprintf('智能体 %d: 分配到任务 %d\n', i, assignedTask);
        end
    else
        fprintf('智能体 %d: 分配异常\n', i);
    end
end

fprintf('\n任务联盟成员情况:\n');
for j = 1:Value_Params.M
    members = find(final_coalition(j, :) ~= 0);
    if ~isempty(members)
        fprintf('任务 %d: 智能体 [%s]\n', j, num2str(members));
    else
        fprintf('任务 %d: 无智能体分配\n', j);
    end
end

% 空联盟成员
emptyMembers = find(final_coalition(Value_Params.M + 1, :) ~= 0);
if ~isempty(emptyMembers)
    fprintf('空联盟: 智能体 [%s]\n', num2str(emptyMembers));
end

fprintf('=====================================\n');

end