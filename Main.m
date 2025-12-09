clear;
clc;
close all;
%for t_iteration=1:50
tic
SEED=24375;
rand('seed',SEED); % 设置随机种子以保证结果可复现
addpath('ColitionFormation');

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
AddPara.NumObs = 20; % 每个智能体对每个任务的观测次数
detprob = 0.9; %识别错误的概率
%% 初始化 agents 和 tasks
for j=1:M
    tasks(j).id=j;
    tasks(j).x=round(rand(1)*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN);
    tasks(j).y=round(rand(1)*(WORLD.YMAX-WORLD.YMIN)+WORLD.YMIN);
    tasks(j).value=WORLD.value(randi(length(WORLD.value),1,1)); 
    tasks(j).WORLD.value=[300,500,1000]; % 
end

for i=1:N
    agents(i).id=i;
    agents(i).vel=2; 
    agents(i).fuel=1; 
    agents(i).x=round(rand(1)*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN);
    agents(i).y=round(rand(1)*(WORLD.YMAX-WORLD.YMIN)+WORLD.YMIN);
    agents(i).detprob = detprob;
end

Value_Params=Value_init(N,M,K,InitialBelief); % 初始化参数结构体 智能体数目N 任务数目M 任务类型数目K

%% 构建初始图
[p, result] = Value_graph(agents, Value_Params);

% 从 result 提取起点 S 和终点 E
S = result(1, :); 
E = result(2, :);

% 构造邻接矩阵 G（N x N），并使其对称得到无向图 Graph
G = zeros(N);
for j=1:size(result,2)
    G(result(1,j),result(2,j))=1;
end
Graph=G+G'; % 一个矩阵表示连接矩阵

% 运行主计算函数，得到价值数据、成本、净收益及初始联盟结构
[Value_data,Rcost,cost_sum,net_profit, initial_coalition]=Value_main(agents,tasks,Graph,Value_Params,AddPara);



%% 提取联盟成员
% 找出每个联盟中非零成员的索引
for j=1:Value_Params.M
    lianmengchengyuan(j).member=find(Value_data(1).coalitionstru(j,:)~=0);
end

%% 打印
% fprintf('Total cost: %.2f\n', 10);
% 
% 
% for i=1:N
%     for j=1:M
%         for k=1:50
%             sumprob(i,j).value(k)=Value_data(i).tasks(j).prob(k,1)*300 + Value_data(i).tasks(j).prob(k,2)*500 + Value_data(i).tasks(j).prob(k,3)*1000;
%         end
%     end
% end
% % 
% % % 绘制每个任务的期望收益曲线（每 4 回合为一点，按 agent 区分）
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
