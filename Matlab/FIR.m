% FIR低通滤波器设计 - 用于高云FPGA
% 要求：100KHz及以下增益为1，1MHz时有大衰减
% 输入输出：12位有符号数

clear all;
close all;
clc;

%% 参数配置
Fs = 3072e4;              % 采样频率 10MHz（可配置）
Fpass = 50e3;          % 通带截止频率 100KHz
Fstop = 8e5;            % 阻带起始频率 0.8MHz
Apass = 1;              % 通带波纹 (dB)
Astop = 60;             % 阻带衰减 (dB)

input_bits = 12;        % 输入位宽3
output_bits = 12;       % 输出位宽
coeff_bits = 12;        % 系数位宽（建议16位以获得更好精度）

%% 设计FIR滤波器
% 归一化频率
Wpass = Fpass / (Fs/2);
Wstop = Fstop / (Fs/2);

% 使用firpm (Parks-McClellan算法) 设计等波纹FIR滤波器
% 估算滤波器阶数
[N, Fo, Ao, W] = firpmord([Fpass Fstop], [1 0], [10^(Apass/20)-1, 10^(-Astop/20)], Fs);

% 如果阶数为偶数，增加1使其为奇数（对称性更好）
if mod(N, 2) == 0
    N = N + 1;
end

fprintf('滤波器阶数: %d\n', N);
fprintf('滤波器抽头数: %d\n', N+1);

% 设计滤波器
b = firpm(N, Fo, Ao, W);

% 归一化系数（使增益为1）
b = b / sum(b);

%% 量化系数
% 将系数量化为定点数
% 使用有符号定点数表示
scale_factor = 2^(coeff_bits-1) - 1;
b_quantized = round(b * scale_factor);

% 限制在有符号整数范围内
b_quantized = max(min(b_quantized, 2^(coeff_bits-1)-1), -2^(coeff_bits-1));

% 转换回浮点数用于分析
b_fixed = b_quantized / scale_factor;

%% 保存系数到文件
% 保存为十进制格式
filename_dec = 'fir_coefficients_dec.txt';
fid = fopen(filename_dec, 'w');
% fprintf(fid, '%% FIR滤波器系数 - 十进制格式\n');
% fprintf(fid, '%% 滤波器阶数: %d\n', N);
% fprintf(fid, '%% 系数位宽: %d bits\n', coeff_bits);
% fprintf(fid, '%% 采样频率: %.2f MHz\n', Fs/1e6);
% fprintf(fid, '%% 通带截止: %.0f KHz\n', Fpass/1e3);
% fprintf(fid, '%% 阻带起始: %.2f MHz\n', Fstop/1e6);
% fprintf(fid, '%% 系数个数: %d\n\n', length(b_quantized));
for i = 1:length(b_quantized)
    fprintf(fid, '%d\n', b_quantized(i));
end
fclose(fid);
fprintf('系数已保存到: %s\n', filename_dec);

% 保存为十六进制格式（可选）
filename_hex = 'fir_coefficients_hex.txt';
fid = fopen(filename_hex, 'w');
fprintf(fid, '%% FIR滤波器系数 - 十六进制格式\n');
fprintf(fid, '%% 每个系数为%d位有符号数\n\n', coeff_bits);
for i = 1:length(b_quantized)
    if b_quantized(i) >= 0
        hex_val = dec2hex(b_quantized(i), coeff_bits/4);
    else
        % 补码表示
        hex_val = dec2hex(2^coeff_bits + b_quantized(i), coeff_bits/4);
    end
    fprintf(fid, '%s\n', hex_val);
end
fclose(fid);
fprintf('系数已保存到: %s\n', filename_hex);

%% 绘制滤波器响应
figure('Position', [100, 100, 1200, 800]);

% 1. 幅频响应 - 线性尺度
subplot(2,2,1);
[H, F] = freqz(b_fixed, 1, 4096, Fs);
plot(F/1e3, abs(H), 'b', 'LineWidth', 1.5);
grid on;
xlabel('频率 (KHz)');
ylabel('幅度');
title('幅频响应 - 线性尺度');
xlim([0 Fs/2e3]);
ylim([0 1.2]);
hold on;
plot([Fpass/1e3 Fpass/1e3], [0 1.2], 'r--', 'LineWidth', 1);
plot([Fstop/1e3 Fstop/1e3], [0 1.2], 'r--', 'LineWidth', 1);
legend('滤波器响应', '通带边界', '阻带边界');

% 2. 幅频响应 - dB尺度
subplot(2,2,2);
plot(F/1e3, 20*log10(abs(H)), 'b', 'LineWidth', 1.5);
grid on;
xlabel('频率 (KHz)');
ylabel('幅度 (dB)');
title('幅频响应 - dB尺度');
xlim([0 Fs/2e3]);
ylim([-100 5]);
hold on;
plot([Fpass/1e3 Fpass/1e3], [-100 5], 'r--', 'LineWidth', 1);
plot([Fstop/1e3 Fstop/1e3], [-100 5], 'r--', 'LineWidth', 1);
plot([0 Fs/2e3], [-Astop -Astop], 'g--', 'LineWidth', 1);
legend('滤波器响应', '通带边界', '阻带边界', '目标衰减');

% 3. 通带细节
subplot(2,2,3);
idx_pass = F <= Fpass*1.5;
plot(F(idx_pass)/1e3, abs(H(idx_pass)), 'b', 'LineWidth', 1.5);
grid on;
xlabel('频率 (KHz)');
ylabel('幅度');
title('通带细节 (0-150KHz)');
ylim([0.95 1.05]);

% 4. 脉冲响应
subplot(2,2,4);
stem(0:N, b_fixed, 'b', 'LineWidth', 1.5);
grid on;
xlabel('样本');
ylabel('幅度');
title('脉冲响应（量化后）');

% 保存图像
saveas(gcf, 'fir_filter_response.png');
fprintf('频率响应图已保存到: fir_filter_response.png\n');

%% 显示关键性能指标
fprintf('\n========== 滤波器性能 ==========\n');

% 通带响应
idx_pass = F <= Fpass;
gain_pass = abs(H(idx_pass));
fprintf('通带增益范围: %.4f - %.4f\n', min(gain_pass), max(gain_pass));
fprintf('通带波纹: %.4f dB\n', 20*log10(max(gain_pass)/min(gain_pass)));

% 1MHz处的衰减
[~, idx_1M] = min(abs(F - 1e6));
atten_1M = 20*log10(abs(H(idx_1M)));
fprintf('1MHz处衰减: %.2f dB\n', atten_1M);

% 阻带衰减
idx_stop = F >= Fstop;
atten_stop = 20*log10(max(abs(H(idx_stop))));
fprintf('阻带最大衰减: %.2f dB\n', atten_stop);

fprintf('\n========== 系数信息 ==========\n');
fprintf('系数个数: %d\n', length(b_quantized));
fprintf('系数位宽: %d bits\n', coeff_bits);
fprintf('系数范围: %d 到 %d\n', min(b_quantized), max(b_quantized));
fprintf('系数总和（归一化）: %.6f\n', sum(b_fixed));

%% 显示前几个系数
fprintf('\n前10个系数（十进制）:\n');
for i = 1:min(10, length(b_quantized))
    fprintf('Coeff[%d] = %d\n', i-1, b_quantized(i));
end

fprintf('\n滤波器设计完成！\n');