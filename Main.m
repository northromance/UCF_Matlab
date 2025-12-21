clear;
clc;
close all;
%for t_iteration=1:50
tic
SEED=24375;
rand('seed',SEED); % 设置随机种子以保证结果可复现
addpath('ColitionFormation');
addpath('SA_ColitionFormation');
addpath('Huo2025');
WORLD.XMIN=0;
WORLD.XMAX=100;
WORLD.YMIN=0;
WORLD.YMAX=100;
WORLD.ZMIN=0;
WORLD.ZMAX=0; % 二维平面
WORLD.value=[300,500,1000]; % 任务价值可能取值集合
%% 输入参数
N=10; % agent 数量
M=6;  % 任务数量
K=3; % 任务类型
InitialBelief = ones(1,K)*1/3; % 初始 belief 分布，均匀分布

% InitialBelief = rand(1, K);  % 随机生成 K 个数字
% InitialBelief = InitialBelief / sum(InitialBelief);  % 归一化，使得和为 1


AddPara.NumObs = 100; % 每个智能体对每个任务的观测次数

AddPara.detprob = 0.9; % 识别错误的概率

AddPara.Temperature = 100; % SA初始温度
AddPara.Tmin = 0.001; % SA最小温度
AddPara.alpha = 0.9; % SA降温系数

AddPara.max_stable_iterations = 20; % 稳定迭代次数
% 完成率随机范围（用户可修改）
AddPara.ComranMin = 0.9; % completion rate 下限
AddPara.ComranMax = 1; % completion rate 上限
%% 算法调试参数
AddPara.control_algorithm = 2;
% 1为贪婪 2 为利他主义 3为全局主义 计算Delta_U(j)

%% 初始化 agents 和 tasks
for j=1:M
    tasks(j).id=j;
    tasks(j).x=round(rand(1)*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN);
    tasks(j).y=round(rand(1)*(WORLD.YMAX-WORLD.YMIN)+WORLD.YMIN);
    tasks(j).value=WORLD.value(randi(length(WORLD.value),1,1));
    tasks(j).WORLD.value=[300,500,1000]; %
    tasks(j).WORLD.risk=[0,0,0]; %

end

for i=1:N
    agents(i).id=i;
    agents(i).vel=2;
    agents(i).fuel=1;
    agents(i).x=round(rand(1)*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN);
    agents(i).y=round(rand(1)*(WORLD.YMAX-WORLD.YMIN)+WORLD.YMIN);
    agents(i).detprob = AddPara.detprob;
    agents(i).detprob = AddPara.detprob;
    % 每个任务的完成率（M个任务），在 [ComranMin, ComranMax] 范围内随机生成
    agents(i).completionRate = AddPara.ComranMin + (AddPara.ComranMax - AddPara.ComranMin).*rand(1,M);
end

Value_Params= Value_init(N,M,K,InitialBelief,AddPara); % 初始化参数结构体 智能体数目N 任务数目M 任务类型数目K

%% 构建初始图
[p, result] = Value_graph(agents, Value_Params);

% 构造无向图邻接矩阵并打印
Graph = zeros(N);
Graph(sub2ind([N,N], result(1,:), result(2,:))) = 1;
Graph = Graph + Graph'; % 对称化得到无向图

fprintf('通信图邻接矩阵 Graph (%d×%d):\n', N, N);
disp(Graph);

% 计算Metropolis-Hastings权重矩阵
W = Metropolis_Hastings_Weights(Graph, Value_Params);
% 运行主计算函数，得到价值数据、最终联盟结构和每轮历史记录

[Me_Value_data, Final_coalitionstru, Coalition_History, Value_data_History] = Value_main(agents,tasks,W,Value_Params,AddPara);

[Huo_Value_data, Rcost,cost_sum, net_profit, initial_coalition] = Huo2025_Value_main(agents,tasks,Graph);

% 显示最终联盟结果
displayCoalitionResult(Final_coalitionstru, Value_Params);
%%
% 绘制每轮联盟总效用变化图（使用每轮的Value_data快照）
plotCoalitionUtility(Coalition_History, Value_data_History, agents, tasks, Value_Params);


%% Huo 绘图


% 联盟成员
for j=1:Value_Params.M
    lianmengchengyuan(j).member=find(Huo_Value_data(1).coalitionstru(j,:)~=0);
end

%% 绘图
figure()
Huo_PlotValue(agents,tasks,lianmengchengyuan,Graph)
axis([0,100,0,100])
% hold on
% initialValue2(TUAVs(RUAV_data(2).accept),RUAVs(2))
% hold on
% initialValue3(TUAVs(RUAV_data(3).accept),RUAVs(3))
xlabel('x-axis (m)','FontName','Times New Roman','FontSize',14)
ylabel('y-axis (m)','FontName','Times New Roman','FontSize',14)
%set(gca, 'FontSize', 12)
grid on

% figure()
% PlotValue(agents,tasks,lianmengchengyuan)
% xlabel('Position in x(m) ','FontSize', 14)
% ylabel('Position in y(m) ','FontSize', 14)
% grid on


%% 绘制分布图
% figure()
% VlineAssignments(agents,tasks,G)
% xlabel('x-axis (m)','FontName','Times New Roman','FontSize',14)
% ylabel('y-axis (m)','FontName','Times New Roman','FontSize',14)
% %set(gca, 'FontSize', 12)
% grid on
% axis([0,100,0,100])



% % 计算最终形成的价值
% for i=1:N % 遍历所有智能体
%     for j=1:M % 遍历所有任务
%         for k=1:50 % 遍历每个任务的50个可能状态或时间点
%             % 对每个任务的prob(k,:)的三个值进行加权求和，存储结果在sumprob(i,j).value(k)
%             sumprob(i,j).value(k)=Huo_Value_data(i).tasks(j).prob(k,1)*300+Huo_Value_data(i).tasks(j).prob(k,2)*500+Huo_Value_data(i).tasks(j).prob(k,3)*1000;
%         end
%     end
% end
% 
% 
% time=1:4:50;
% for j=1:M
%     figure()
%     plot(time,sumprob(1,j).value(1:4:50),'-+',time,sumprob(2,j).value(1:4:50),'-o',time,sumprob(3,j).value(1:4:50),'-x',time,sumprob(4,j).value(1:4:50),'-*',time,sumprob(5,j).value(1:4:50),'-v'...
%         ,time,sumprob(6,j).value(1:4:50),'-^',time,sumprob(7,j).value(1:4:50),'-s',time,sumprob(8,j).value(1:4:50),'-d',time,sumprob(9,j).value(1:4:50),'-p',time,sumprob(10,j).value(1:4:50),'-h')
%     h=legend('$r_1$','$r_2$','$r_3$','$r_4$','$r_5$','$r_6$','$r_7$','$r_8$','$r_9$','$r_{10}$');
%     set(h,'Interpreter','latex','FontName','Times New Roman','FontSize',12,'FontWeight','normal');
%     xlabel('Index of game','FontName','Times New Roman','FontSize',14);
%     ylabel('Expected task revenue','FontName','Times New Roman','FontSize',14);
%     grid on
% end
%%
figure()
plot(1:50,net_profit,'o-')
xlabel('Number of iterations ','FontSize', 14)
ylabel('Global utility ','FontSize', 14)
set(gca, 'FontSize', 12)
grid on
