%  ROCKET STAGING OPTIMIZER
%  Optimizes 2-stage rocket design for maximum payload fraction
%  using the Tsiolkovsky rocket equation and staging analysis
%
clc; clear; close all;

%% 1. USER INPUT 
fprintf('\n╔══════════════════════════════════════╗\n');
fprintf(  '║      ROCKET STAGING OPTIMIZER        ║\n');
fprintf(  '║   Press Enter to use default value.  ║\n');
fprintf(  '╚══════════════════════════════════════╝\n\n');

fprintf('── MISSION REQUIREMENTS ────────────────\n');
dv_total  = input_val('  Total delta-v required      [m/s]  (default 9400 ) : ', 9400);
m_payload = input_val('  Payload mass                [kg]   (default  100 ) : ', 100);

fprintf('\n── STAGE 1 PARAMETERS ──────────────────\n');
fprintf('   Isp presets: kerosene/LOX=310  LH2/LOX=450  solid=280\n\n');
Isp1      = input_val('  Stage 1 specific impulse    [s]    (default  310 ) : ', 310);
eps1      = input_val('  Stage 1 structural fraction [-]    (default  0.08) : ', 0.08);

fprintf('\n── STAGE 2 PARAMETERS ──────────────────\n');
Isp2      = input_val('  Stage 2 specific impulse    [s]    (default  450 ) : ', 450);
eps2      = input_val('  Stage 2 structural fraction [-]    (default  0.10) : ', 0.10);

fprintf('\n── OPTIMIZATION SETTINGS ───────────────\n');
n_sweep   = input_val('  Number of sweep points      [-]    (default  200 ) : ', 200);
fprintf('\n');

% Constants
g0 = 9.81;   % [m/s^2] standard gravity

%% 2. SINGLE-STAGE REFERENCE 
% Single stage to orbit for comparison
fprintf('Computing single-stage reference...\n');
R_ssto = exp(dv_total / (310 * g0));   % mass ratio needed
lambda_ssto = (1 - eps1 * R_ssto) / R_ssto;
if lambda_ssto > 0
    fprintf('  Single-stage payload fraction: %.4f (%.2f%%)\n', ...
            lambda_ssto, lambda_ssto*100);
else
    fprintf('  Single-stage to orbit: NOT FEASIBLE with given Isp/structure\n');
end

%% 3. DELTA-V SPLIT SWEEP 
fprintf('Running delta-v split sweep...\n');

dv1_vec      = linspace(0.05*dv_total, 0.95*dv_total, n_sweep);
dv2_vec      = dv_total - dv1_vec;
lambda_vec   = zeros(1, n_sweep);   % payload fraction
m0_vec       = zeros(1, n_sweep);   % total initial mass
mr1_vec      = zeros(1, n_sweep);   % stage 1 mass ratio
mr2_vec      = zeros(1, n_sweep);   % stage 2 mass ratio

for k = 1:n_sweep
    dv1 = dv1_vec(k);
    dv2 = dv2_vec(k);

    % Mass ratios from Tsiolkovsky
    MR1 = exp(dv1 / (Isp1 * g0));   % m0/mf stage 1
    MR2 = exp(dv2 / (Isp2 * g0));   % m0/mf stage 2

    % Payload fractions per stage
    lam1 = (1/MR1 - eps1) / (1 - eps1);
    lam2 = (1/MR2 - eps2) / (1 - eps2);

    mr1_vec(k) = MR1;
    mr2_vec(k) = MR2;

    if lam1 > 0 && lam2 > 0
        lambda_vec(k) = lam1 * lam2;   % total payload fraction
        m0_vec(k)     = m_payload / lambda_vec(k);
    else
        lambda_vec(k) = NaN;
        m0_vec(k)     = NaN;
    end
end

%% 4. FIND OPTIMUM 
[lambda_opt, idx_opt] = max(lambda_vec);
dv1_opt = dv1_vec(idx_opt);
dv2_opt = dv2_vec(idx_opt);
MR1_opt = mr1_vec(idx_opt);
MR2_opt = mr2_vec(idx_opt);
m0_opt  = m_payload / lambda_opt;

% Stage mass breakdown at optimum
lam2_opt   = (1/MR2_opt - eps2) / (1 - eps2);
lam1_opt   = lambda_opt / lam2_opt;

% Stage 2 total mass (payload + stage 2 hardware + propellant)
m_stage2_total = m_payload / lam2_opt;
m_struct2      = eps2 * (m_stage2_total - m_payload);
m_prop2        = m_stage2_total - m_payload - m_struct2;

% Stage 1 total mass
m_stage1_total = m0_opt - m_stage2_total;
m_struct1      = eps1 * (m_stage1_total);
m_prop1        = m_stage1_total - m_struct1;

%% 5. FLIGHT SUMMARY 
fprintf('\n======================================\n');
fprintf('  STAGING OPTIMIZATION RESULTS\n');
fprintf('======================================\n');
fprintf('  Target delta-v       : %.0f m/s\n',    dv_total);
fprintf('  Optimal dv split     : %.0f / %.0f m/s\n', dv1_opt, dv2_opt);
fprintf('  dv fraction stage 1  : %.1f%%\n',      100*dv1_opt/dv_total);
fprintf('--------------------------------------\n');
fprintf('  STAGE 1\n');
fprintf('    Mass ratio         : %.3f\n',         MR1_opt);
fprintf('    Propellant mass    : %.1f kg\n',       m_prop1);
fprintf('    Structural mass    : %.1f kg\n',       m_struct1);
fprintf('    Total mass         : %.1f kg\n',       m_stage1_total);
fprintf('  STAGE 2\n');
fprintf('    Mass ratio         : %.3f\n',         MR2_opt);
fprintf('    Propellant mass    : %.1f kg\n',       m_prop2);
fprintf('    Structural mass    : %.1f kg\n',       m_struct2);
fprintf('    Total mass         : %.1f kg\n',       m_stage2_total);
fprintf('--------------------------------------\n');
fprintf('  Payload mass         : %.1f kg\n',       m_payload);
fprintf('  Total liftoff mass   : %.1f kg\n',       m0_opt);
fprintf('  Payload fraction     : %.4f (%.2f%%)\n', lambda_opt, lambda_opt*100);
fprintf('======================================\n\n');

%% 6. PLOTS 
bg       = [0.08 0.08 0.12];
col1     = [0.20 0.75 1.00];   % cyan
col2     = [1.00 0.55 0.10];   % orange
col_opt  = [1.00 1.00 0.20];   % yellow
col_mass = [0.60 1.00 0.40];   % green
col_mr   = [1.00 0.30 0.30];   % red

fig = figure('Name','Rocket Staging Optimizer', ...
             'Color', bg, 'Position', [100 80 1200 800]);

% Plot 1: Payload Fraction vs dv Split 
ax1 = subplot(2,3,[1,2]);
plot(dv1_vec/1000, lambda_vec*100, '-', 'Color', col1, 'LineWidth', 2.5); hold on;
plot(dv1_opt/1000, lambda_opt*100, 'p', 'Color', col_opt, ...
     'MarkerSize', 14, 'MarkerFaceColor', col_opt);
text(dv1_opt/1000 + 0.1, lambda_opt*100, ...
     sprintf('  Optimum\n  dv1=%.0fm/s\n  %.3f%%', dv1_opt, lambda_opt*100), ...
     'Color', col_opt, 'FontSize', 9, 'FontWeight', 'bold');
if lambda_ssto > 0
    yline(lambda_ssto*100, '--', 'Color', col2, 'LineWidth', 1.5);
    text(dv1_vec(10)/1000, lambda_ssto*100 + 0.05, 'Single Stage', ...
         'Color', col2, 'FontSize', 8);
end
style_axes(ax1, bg);
xlabel('Stage 1 Delta-v (km/s)', 'Color', 'w');
ylabel('Payload Fraction (%)', 'Color', 'w');
title('Payload Fraction vs Delta-v Split', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Plot 2: Total Liftoff Mass vs dv Split 
ax2 = subplot(2,3,3);
plot(dv1_vec/1000, m0_vec, '-', 'Color', col_mass, 'LineWidth', 2); hold on;
plot(dv1_opt/1000, m0_opt, 'p', 'Color', col_opt, ...
     'MarkerSize', 12, 'MarkerFaceColor', col_opt);
style_axes(ax2, bg);
xlabel('Stage 1 Delta-v (km/s)', 'Color', 'w');
ylabel('Liftoff Mass (kg)', 'Color', 'w');
title('Total Liftoff Mass vs Delta-v Split', 'Color', 'w', 'FontSize', 11);
grid on;

% Plot 3: Mass Ratios vs dv Split 
ax3 = subplot(2,3,4);
plot(dv1_vec/1000, mr1_vec, '-', 'Color', col1, 'LineWidth', 2, ...
     'DisplayName', 'Stage 1'); hold on;
plot(dv1_vec/1000, mr2_vec, '-', 'Color', col2, 'LineWidth', 2, ...
     'DisplayName', 'Stage 2');
xline(dv1_opt/1000, '--', 'Color', col_opt, 'LineWidth', 1.2);
legend('TextColor', 'w', 'Color', bg, 'EdgeColor', [0.4 0.4 0.4], 'FontSize', 8);
style_axes(ax3, bg);
xlabel('Stage 1 Delta-v (km/s)', 'Color', 'w');
ylabel('Mass Ratio (m0/mf)', 'Color', 'w');
title('Stage Mass Ratios vs Delta-v Split', 'Color', 'w', 'FontSize', 11);
grid on;

% Plot 4: Mass Breakdown Pie at Optimum 
ax4 = subplot(2,3,5);
masses = [m_prop1, m_struct1, m_prop2, m_struct2, m_payload];
labels = {sprintf('S1 Propellant\n%.1f kg', m_prop1), ...
          sprintf('S1 Structure\n%.1f kg', m_struct1), ...
          sprintf('S2 Propellant\n%.1f kg', m_prop2), ...
          sprintf('S2 Structure\n%.1f kg', m_struct2), ...
          sprintf('Payload\n%.1f kg', m_payload)};
colors = [0.20 0.75 1.00;
          0.10 0.40 0.60;
          1.00 0.55 0.10;
          0.60 0.30 0.05;
          0.60 1.00 0.40];
pie(ax4, masses);
p = pie(ax4, masses, labels);
for k = 1:2:length(p)
    p(k).FaceColor = colors(ceil(k/2), :);
    p(k).EdgeColor = bg;
end
for k = 2:2:length(p)
    p(k).Color = 'w';
    p(k).FontSize = 7;
end
title('Mass Breakdown at Optimum', 'Color', 'w', 'FontSize', 11);
set(ax4, 'Color', bg);

% Plot 5: Isp Sensitivity 
ax5 = subplot(2,3,6);
Isp2_range = linspace(250, 600, 100);
lam_sens   = zeros(size(Isp2_range));
for k = 1:length(Isp2_range)
    MR1s = exp(dv1_opt / (Isp1 * g0));
    MR2s = exp(dv2_opt / (Isp2_range(k) * g0));
    l1 = (1/MR1s - eps1) / (1 - eps1);
    l2 = (1/MR2s - eps2) / (1 - eps2);
    if l1 > 0 && l2 > 0
        lam_sens(k) = l1 * l2 * 100;
    else
        lam_sens(k) = NaN;
    end
end
plot(Isp2_range, lam_sens, '-', 'Color', col_mr, 'LineWidth', 2); hold on;
xline(Isp2, '--', 'Color', col_opt, 'LineWidth', 1.2);
text(Isp2 + 5, max(lam_sens, [], 'omitnan')*0.95, ...
     sprintf('Current\nIsp2=%ds', Isp2), 'Color', col_opt, 'FontSize', 8);
style_axes(ax5, bg);
xlabel('Stage 2 Isp (s)', 'Color', 'w');
ylabel('Payload Fraction (%)', 'Color', 'w');
title('Payload Fraction vs Stage 2 Isp', 'Color', 'w', 'FontSize', 11);
grid on;

sgtitle('Rocket Staging Optimizer', ...
        'Color', 'w', 'FontSize', 15, 'FontWeight', 'bold');

fprintf('Done.\n');

%  LOCAL FUNCTIONS
function style_axes(ax, bg)
    set(ax, 'Color', bg, 'XColor', 'w', 'YColor', 'w', ...
        'GridColor', [0.3 0.3 0.3], 'MinorGridColor', [0.2 0.2 0.2]);
end

function val = input_val(prompt, default)
    raw = input(prompt, 's');
    if isempty(strtrim(raw))
        val = default;
    else
        val = str2double(raw);
        if isnan(val)
            fprintf('  Invalid input, using default: %g\n', default);
            val = default;
        end
    end
end
