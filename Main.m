clear;
% 清除工作区并初始化
clc;
close all;
%for t_iteration=1:50
tic
SEED=24375;
rand('seed',SEED); % 设置随机种子以保证结果可复现

WORLD.XMIN=0;
WORLD.XMAX=100;
WORLD.YMIN=0;
WORLD.YMAX=100;
WORLD.ZMIN=0;
WORLD.ZMAX=0; % 二维平面
WORLD.value=[300,500,1000]; % 任务价值可能取值集合

N=10; % agent 数量
M=6;  % 任务数量

%% 初始化 agents 和 tasks
for j=1:M
    tasks(j).id=j;
    tasks(j).x=round(rand(1)*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN);
    tasks(j).y=round(rand(1)*(WORLD.YMAX-WORLD.YMIN)+WORLD.YMIN);
    % tasks(j).z=rand(1)*(WORLD.ZMAX-WORLD.ZMIN)+WORLD.ZMIN; % 如需 3 维可启用
    tasks(j).value=WORLD.value(randi(length(WORLD.value),1,1)); % 随机分配任务价值
    tasks(j).WORLD.value=[300,500,1000]; % 任务可能价值的冗余存储
end

for i=1:N
    agents(i).id=i;
    agents(i).vel=2; % 巡逻速度
    agents(i).fuel=1; % 燃料/单位距离 (示例值)
    agents(i).x=round(rand(1)*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN);
    agents(i).y=round(rand(1)*(WORLD.YMAX-WORLD.YMIN)+WORLD.YMIN);
    % agents(i).detprob=0.9+randn(1); % 可用于设置探测概率的随机化示例
end
for i=1:N
    agents(i).detprob=1; % 探测概率（当前设为 1）
    %agents(i).detprob=0.9+0.1*rand(1);
end
% 可选：将初始化数据保存到文件（示例路径，已注释）
% save('C:\Users\UGV\Desktop\data1.mat','agents','tasks','N','M')
Value_Params=Value_init(N,M);

%% 构建初始图
% 生成图结构（用于建模 agent 间的邻接关系）并返回结果
[p, result] = Value_graph(agents, Value_Params);

% 从 result 提取起点 S 和终点 E
S = result(1, :);
E = result(2, :);

% 构造邻接矩阵 G（N x N），并使其对称得到无向图 Graph
G = zeros(N);
for j=1:size(result,2)
    G(result(1,j),result(2,j))=1;
end
Graph=G+G';

% 运行主计算函数，得到价值数据、成本、净收益及初始联盟结构
[Value_data,Rcost,cost_sum,net_profit, initial_coalition]=Value_main(agents,tasks,Graph);
toc

%  total_toc(t_iteration)=toc;
%  initial_profit(t_iteration)=net_profit(1);
%  total_profit(t_iteration)=net_profit(end);
% end

%% 提取联盟成员
% 找出每个联盟中非零成员的索引
for j=1:Value_Params.M
    lianmengchengyuan(j).member=find(Value_data(1).coalitionstru(j,:)~=0);
end

% 绘制任务与 agent 的分配情况
figure()
PlotValue(agents,tasks,lianmengchengyuan,G)
axis([0,100,0,100])
xlabel('x-axis (m)','FontName','Times New Roman','FontSize',14)
ylabel('y-axis (m)','FontName','Times New Roman','FontSize',14)
grid on

% figure()
% PlotValue(agents,tasks,lianmengchengyuan)
% xlabel('Position in x(m) ','FontSize', 14)
% ylabel('Position in y(m) ','FontSize', 14)
% grid on

% 绘制任务分配连线图
figure()
VlineAssignments(agents,tasks,G)
xlabel('x-axis (m)','FontName','Times New Roman','FontSize',14)
ylabel('y-axis (m)','FontName','Times New Roman','FontSize',14)
grid on
axis([0,100,0,100])



% 计算每个 agent 对每个任务在各回合的期望收益
for i=1:N
    for j=1:M
        for k=1:50
            sumprob(i,j).value(k)=Value_data(i).tasks(j).prob(k,1)*300 + Value_data(i).tasks(j).prob(k,2)*500 + Value_data(i).tasks(j).prob(k,3)*1000;
        end
    end
end

% 绘制每个任务的期望收益曲线（每 4 回合为一点，按 agent 区分）
time=1:4:50;
for j=1:M
    figure()
    plot(time,sumprob(1,j).value(1:4:50),'-+',time,sumprob(2,j).value(1:4:50),'-o',time,sumprob(3,j).value(1:4:50),'-x',time,sumprob(4,j).value(1:4:50),'-*',time,sumprob(5,j).value(1:4:50),'-v'...
        ,time,sumprob(6,j).value(1:4:50),'-^',time,sumprob(7,j).value(1:4:50),'-s',time,sumprob(8,j).value(1:4:50),'-d',time,sumprob(9,j).value(1:4:50),'-p',time,sumprob(10,j).value(1:4:50),'-h')
    h=legend('$r_1$','$r_2$','$r_3$','$r_4$','$r_5$','$r_6$','$r_7$','$r_8$','$r_9$','$r_{10}$');
    set(h,'Interpreter','latex','FontName','Times New Roman','FontSize',12,'FontWeight','normal');
    xlabel('Index of game','FontName','Times New Roman','FontSize',14);
    ylabel('Expected task revenue','FontName','Times New Roman','FontSize',14);
    grid on
end

% 绘制全局效用随迭代次数的变化
figure()
plot(1:20,net_profit,'o-')
xlabel('Number of iterations ','FontSize', 14)
ylabel('Global utility ','FontSize', 14)
set(gca, 'FontSize', 12)
grid on
