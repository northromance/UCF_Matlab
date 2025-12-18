function Value_Params=Value_init(N,M,K,InitialBelief,AddPara)
Value_Params.N=N;
Value_Params.M=M;
Value_Params.K=K;
Value_Params.InitialBelief = InitialBelief;
Value_Params.Temperature= AddPara.Temperature;
Value_Params.alpha = AddPara.alpha;
Value_Params.Tmin = AddPara.Tmin;
Value_Params.max_stable_iterations = AddPara.max_stable_iterations;
end