function [incremental,curRow,Value_data]=Value_order(agents, tasks, Value_data, Value_Params)
% 主要变量说明:
% incremental: 联盟结构是否改变的标志位
% curRow/curCol: 当前智能体的任务行号和列号
% curMembers: 当前任务的联盟成员
% curUtil: 当前智能体效用
% candMembers: 候选任务的联盟成员
% candUtil: 候选任务效用数组
% maxUtil/bestTask: 最大效用值和对应任务索引

incremental=0; % 用于判断联盟结构是否改变的标志位
AValue_data.coalitionBackup = Value_data.coalitionstru; % 备份联盟结构，后面涉及联盟结构调整
AValue_data.iterationBackup = Value_data.iteration; % 备份迭代次数
AValue_data.unifBackup = Value_data.unif; % 备份随机变量

[curRow, curCol] = find(Value_data.coalitionstru == Value_data.agentID); 
% curRow 为 agent 当前任务行号，curCol 为列号
curMembers = find(Value_data.coalitionstru(curRow,:)~=0);
% agent所在联盟的全部成员
curUtil = Value_utility(agents, tasks,curRow,curCol, curMembers,Value_data,Value_Params); 
% 计算agent当前效用


%找到效用最大的任务索引
for j=1:Value_Params.M+1
    Value_data.coalitionstru = AValue_data.coalitionBackup; % 保证每个任务的联盟结构一致
    Value_data.coalitionstru(curRow,curCol)=0;
    Value_data.coalitionstru(j,Value_data.agentID)=Value_data.agentID; 
    candMembers = find(Value_data.coalitionstru(j,:)~=0); % 提取agent所在新任务联盟的全部成员
    candUtil(j) = Value_utility(agents, tasks, j, Value_data.agentID, candMembers,Value_data,Value_Params); % 调用utility函数
    Value_data.agentID;
end

[maxUtil,bestTask] = max(candUtil); % 找到对应最大效用值的任务索引
% [maxUtil,bestTask]=sort(candUtil,'descend'); % 降序排列

if maxUtil==0 
      Value_data.coalitionstru = AValue_data.coalitionBackup;
      Value_data.coalitionstru(curRow,curCol) = 0;
      Value_data.coalitionstru(Value_Params.M+1,curCol)=Value_data.agentID;
else
    
    if  maxUtil > curUtil
             incremental=1;
             Value_data.iteration= Value_data.iteration+1; % 联盟改变次数
             Value_data.unif=rand(1); % 均匀随机变量
    end
end
    
    if incremental==0
       Value_data.coalitionstru = AValue_data.coalitionBackup;
    else
      Value_data.coalitionstru = AValue_data.coalitionBackup;
      Value_data.coalitionstru(curRow,curCol) = 0;
      Value_data.coalitionstru(bestTask,curCol) = Value_data.agentID;
    end

end
