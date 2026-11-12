%% Step 2b: honeycomb sandwich panel

clear; close all; clc;
p = panel_params();
if ~exist(p.fig_dir, 'dir'), mkdir(p.fig_dir); end
Ef = p.mat(1).E; rho_f = p.mat(1).rho;   % aluminium face sheets
tf = p.sw.t_face;

hc_sweep = linspace(2e-3, 20e-3, 46);   % core thickness (m)
f1 = zeros(size(hc_sweep)); mass = f1;
for k = 1:numel(hc_sweep)
    [f1(k), mass(k)] = sandwich_f1(hc_sweep(k), tf, Ef, rho_f, p);
end

% Smallest standard core thickness that meets the target
hc_std = [3 5 6 8 10 12 15 20] * 1e-3;
fprintf('STEP 2b: sandwich panel, Al faces %.1f mm each, core %.0f kg/m^3\n', ...
        tf*1e3, p.sw.rho_core);
fprintf('%-12s %10s %12s %8s\n', 'core (mm)', 'f1 (Hz)', 'mass (g)', 'OK?');
chosen = [];
for hc = hc_std
    [f, m] = sandwich_f1(hc, tf, Ef, rho_f, p);
    ok = f >= p.f_target;
    if ok, ok_txt = 'yes'; else, ok_txt = 'no'; end
    fprintf('%-12.0f %10.1f %12.1f %8s\n', hc*1e3, f, m*1e3, ok_txt);
    if ok && isempty(chosen), chosen = [hc f m]; end
end

% Compare with the solid aluminium baseline from step 2
load('design_result.mat', 'design');
fprintf('\nComparison (same length, width and tip mass):\n');
fprintf('  Solid Al, %.1f mm:            f1 = %5.1f Hz, panel mass = %4.0f g\n', ...
        design.t*1e3, design.res.f(1), design.rhoA*p.L*1e3);
fprintf('  Sandwich, %.0f mm core:        f1 = %5.1f Hz, panel mass = %4.0f g\n', ...
        chosen(1)*1e3, chosen(2), chosen(3)*1e3);
fprintf('  Mass saving: %.0f%%\n', (1 - chosen(3)/(design.rhoA*p.L))*100);

% Figure 7: f1 vs mass for all three concepts
t_sweep = linspace(1e-3, 7e-3, 61);
c = [0.165 0.471 0.839; 0.922 0.408 0.204; 0.106 0.686 0.478];
fig = figure('Position', [100 100 640 440]);
hold on;
for i = 1:2
    mat = p.mat(i);
    fs = zeros(size(t_sweep)); ms = fs;
    for k = 1:numel(t_sweep)
        I = p.b*t_sweep(k)^3/12; rhoA = mat.rho*p.b*t_sweep(k);
        r = beam_fem(p.L, mat.E, I, rhoA, p.m_tip, p.n_el, 1);
        fs(k) = r.f(1); ms(k) = rhoA*p.L;
    end
    plot(ms*1e3, fs, '-', 'Color', c(i,:), 'LineWidth', 1.5);
end
plot(mass*1e3, f1, '-', 'Color', c(3,:), 'LineWidth', 1.5);
plot([0 600], [p.f_req p.f_req], 'k--', 'LineWidth', 1);
plot(chosen(3)*1e3, chosen(2), 'o', 'Color', c(3,:), 'MarkerSize', 8, ...
     'MarkerFaceColor', c(3,:));
xlim([0 600]); ylim([0 150]);
xlabel('Panel mass without tip mass (g)');
ylabel('First natural frequency f_1 (Hz)');
title('Three panel concepts');
legend('Solid Al 6061', 'Solid CFRP', 'Al honeycomb sandwich', ...
       'Requirement 40 Hz', 'Chosen sandwich', 'Location', 'northeast');
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig7_concepts.png'), '-dpng', '-r200');
fprintf('\nFigure saved to %s\n', p.fig_dir);
