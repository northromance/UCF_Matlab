function r = drchrnd(a, n)
    p = length(a);  % a的长度，表示Dirichlet分布的维度
    r = gamrnd(repmat(a, n, 1), 1, n, p);  % 从Gamma分布中生成随机数
    r = r ./ repmat(sum(r, 2), 1, p);  % 对每一行进行归一化
end
