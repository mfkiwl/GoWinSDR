% 系统参数
M = 4;                 % QPSK 调制阶数
Fs = 10e6;             % 采样率
Rsym = 1e6;            % 符号速率
SpS = Fs/Rsym;         % 每符号采样点数 (例如 10)
NumSym = 1000;         % 仿真符号数
SNR_dB = 10;           % 信噪比

% 载波误差 (用于模拟 Tx/Rx LO 不同步)
FreqErr = 10e3;        % 频率误差 (Hz)
PhaseErr_rad = pi/3;   % 初始相位误差 (弧度，60度)

% 科斯塔斯环路参数 (关键!)
zeta = 0.707;          % 阻尼比 (通常取 0.707 获得最佳瞬态响应)
BnTs = 0.01;           % 归一化环路带宽 Bn * Ts (Ts=1/Fs)
K_d = 1;               % 鉴相器增益 (QPSK Costas Loop 近似为 1)

% 计算环路滤波器增益 (Kp 和 Ki)
% Ts = 1/Fs;
% Wn = BnTs / (zeta*Ts + 0.25/zeta/Ts); % 根据 BnTs 和 zeta 计算自然频率
% 
% % Type-II Loop Filter 增益计算公式 (简化后)
% theta = Wn * Ts;
% K_P = (theta / K_d) * (1 + 2 * zeta * theta);
% K_I = (theta^2 / K_d);
% 
% --- 简化计算，直接使用 BnTs 和 zeta ---
K_g = 1 / (SpS); % 总环路增益简化
Wn = BnTs * Rsym;
D = 1 + 2*zeta*Wn/Rsym + (Wn/Rsym)^2;
K_P = 4*zeta*Wn/Rsym / D / K_d;
K_I = 4*(Wn/Rsym)^2 / D / K_d;

% NCO 累加器和输出
Phase_NCO = 0; % NCO 累加相位
Phase_Err_Vector = zeros(1, NumSym * SpS); % 记录误差

% 生成随机 QPSK 符号 (假设为理想符号)
DataIn = randi([0 M-1], NumSym, 1);
TxSym = qammod(DataIn, M, 'InputType', 'integer', 'UnitAveragePower', true); 

% 过采样和脉冲成形 (使用升余弦滤波器)
TxSignal = upsample(TxSym, SpS);
h_rc = rcosdesign(0.35, 6, SpS);
TxSignal_rc = conv(TxSignal, h_rc, 'same');

% 引入载波和噪声误差
TimeVector = (0:length(TxSignal_rc)-1)' / Fs;
CarrierErr = exp(1j * (2*pi*FreqErr*TimeVector + PhaseErr_rad));
RxSignal = TxSignal_rc .* CarrierErr;
RxSignal_Noisy = awgn(RxSignal, SNR_dB, 'measured');

% AD9363 接收的 I/Q 基带信号 (复数形式)
RxI = real(RxSignal_Noisy);
RxQ = imag(RxSignal_Noisy);

% 初始化环路状态
I_sync = zeros(size(RxI));
Q_sync = zeros(size(RxQ));
Filter_Integrator = 0; % 环路滤波器积分项

for n = 1:length(RxI)
    
    % --- 1. NCO 输出 ---
    NCO_Output = exp(-1j * Phase_NCO); % NCO 相位用于解旋
    
    % --- 2. 数字解旋 (Mixer) ---
    RxSignal_in = RxI(n) + 1j * RxQ(n);
    RxSignal_DDC = RxSignal_in * NCO_Output;
    
    I_DDC = real(RxSignal_DDC);
    Q_DDC = imag(RxSignal_DDC);
    
    % --- 3. 判决/限幅 (Symbol Slicer/Detector) ---
    % 注意：鉴相器在每个采样点都运行，但我们通常在符号中心进行判决
    
    % --- 4. 鉴相器 (Phase Detector, PD) ---
    % QPSK 误差函数: e[n] = I' * sgn(Q') - Q' * sgn(I')
    % 简化: sgn(x) 用 hard decision 替代
    
    % 判决项 (sgn(I') 和 sgn(Q')):
    sgn_I = sign(I_DDC);
    sgn_Q = sign(Q_DDC);
    
    % 鉴相误差计算:
    e_n = I_DDC * sgn_Q - Q_DDC * sgn_I;
    
    % --- 5. 环路滤波器 (Loop Filter, PI 控制器) ---
    % 比例项
    P_out = K_P * e_n;
    
    % 积分项 (更新和输出)
    Filter_Integrator = Filter_Integrator + K_I * e_n;
    I_out = Filter_Integrator;
    
    % 频率控制字 (输入 NCO 的频率步进)
    Freq_Ctrl_Word = P_out + I_out;
    
    % --- 6. NCO 累加器更新 ---
    % NCO 累加器更新： Phase_NCO(n+1) = Phase_NCO(n) + Freq_Ctrl_Word
    Phase_NCO = Phase_NCO + Freq_Ctrl_Word;
    
    % 记录结果 (可选)
    Phase_Err_Vector(n) = FreqErr * TimeVector(n) + PhaseErr_rad - Phase_NCO;
    I_sync(n) = I_DDC;
    Q_sync(n) = Q_DDC;
end

% 同步后的复数信号
RxSyncSignal = I_sync + 1j * Q_sync;

% 星座图
figure;
subplot(1, 2, 1);
plot(real(RxSignal_Noisy), imag(RxSignal_Noisy), 'b.');
title('接收信号星座图 (未同步)');
xlabel('I'); ylabel('Q'); axis equal;

subplot(1, 2, 2);
plot(I_sync, Q_sync, 'r.');
title('同步后信号星座图 (科斯塔斯环)');
xlabel('I'); ylabel('Q'); axis equal;
ylim([-1.5 1.5]); xlim([-1.5 1.5]);

% 环路误差跟踪
figure;
plot(TimeVector, Phase_Err_Vector * 180 / pi);
title('科斯塔斯环路相位误差跟踪');
xlabel('时间 (s)');
ylabel('相位误差 (度)');
grid on;
