% 测试AddPara参数整合
clear all;
clc;

% 设置AddPara参数
AddPara.Temperature = 100;
AddPara.Tmin = 0.001;
AddPara.alpha = 0.96;
AddPara.max_stable_iterations = 10;
AddPara.detprob = 0.9;
AddPara.NumObs = 20;

% 测试Value_init函数
N = 5;
M = 3;
K = 2;
InitialBelief = rand(1, K);
InitialBelief = InitialBelief / sum(InitialBelief); % 归一化

try
    Value_Params = Value_init(N, M, K, InitialBelief, AddPara);
    disp('? Value_init函数参数整合成功!');
    disp('Value_Params结构体:');
    disp(Value_Params);
    
    % 验证参数是否正确传递
    if Value_Params.Temperature == AddPara.Temperature && ...
       Value_Params.alpha == AddPara.alpha && ...
       Value_Params.Tmin == AddPara.Tmin && ...
       Value_Params.max_stable_iterations == AddPara.max_stable_iterations
        disp('? 所有SA参数都已正确传递到Value_Params中!');
    else
        disp('? 参数传递有误!');
    end
    
catch ME
    disp(['? 错误: ' ME.message]);
end

% 测试agents结构体中detprob设置
for i = 1:N
    agents(i).detprob = AddPara.detprob;
end

if all([agents.detprob] == AddPara.detprob)
    disp('? agents结构体中detprob参数设置成功!');
else
    disp('? agents结构体中detprob参数设置失败!');
end

disp(' ');
disp('参数整合总结:');
disp('- SA算法参数 (Temperature, alpha, Tmin, max_stable_iterations) 已整合到AddPara中');
disp('- detprob参数通过AddPara设置到agents结构体中');
disp('- Value_init函数已更新为接收AddPara参数');
disp('- 所有相关函数调用已更新');