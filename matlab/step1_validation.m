%% Step 1: check FEM code with exact cantilever solution

clear; close all; clc;
p = panel_params();
if ~exist(p.fig_dir, 'dir'), mkdir(p.fig_dir); end

mat = p.mat(1);   % aluminium
t   = 2.0e-3;
I    = p.b * t^3 / 12;
rhoA = mat.rho * p.b * t;

betaL   = [1.875104, 4.694091, 7.854757];
f_exact = betaL.^2 * sqrt(mat.E*I / (rhoA*p.L^4)) / (2*pi);

n_list = [1 2 4 8 16 32];
f_fem  = nan(numel(n_list), 3);
for k = 1:numel(n_list)
    r = beam_fem(p.L, mat.E, I, rhoA, 0, n_list(k), 3);
    f_fem(k, 1:numel(r.f)) = r.f';
end
err = abs(f_fem - f_exact) ./ f_exact * 100;

fprintf('STEP 1: FEM validation, bare cantilever, %s, t = %.1f mm\n', mat.name, t*1e3);
fprintf('Exact:      f1 = %7.2f Hz   f2 = %7.2f Hz   f3 = %7.2f Hz\n', f_exact);
fprintf('%-8s %10s %10s %10s %10s %10s %10s\n', 'n_el', 'f1 (Hz)', 'err1 (%)', ...
        'f2 (Hz)', 'err2 (%)', 'f3 (Hz)', 'err3 (%)');
for k = 1:numel(n_list)
    fprintf('%-8d %10.3f %10.4f %10.3f %10.4f %10.3f %10.4f\n', n_list(k), ...
        f_fem(k,1), err(k,1), f_fem(k,2), err(k,2), f_fem(k,3), err(k,3));
end

% Figure 1: convergence
c = [0.165 0.471 0.839; 0.922 0.408 0.204; 0.106 0.686 0.478];
fig = figure('Position', [100 100 640 440]);
hold on;
for m = 1:3
    ok = ~isnan(err(:, m)) & err(:, m) > 0;
    loglog(n_list(ok), err(ok, m), '-o', 'Color', c(m,:), 'LineWidth', 1.5, ...
        'MarkerSize', 6, 'MarkerFaceColor', c(m,:));
end
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('Number of elements');
ylabel('Error vs exact solution (%)');
title('FEM convergence, uniform cantilever');
legend('Mode 1', 'Mode 2', 'Mode 3', 'Location', 'northeast');
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig1_convergence.png'), '-dpng', '-r200');

% Figure 2: first three mode shapes
r = beam_fem(p.L, mat.E, I, rhoA, 0, 32, 3);
w = r.Phi(1:2:end, :);   % deflection DOFs only
w = w ./ max(abs(w));
fig = figure('Position', [100 100 640 440]);
hold on;
for m = 1:3
    plot(r.x*1e3, w(:, m), '-', 'Color', c(m,:), 'LineWidth', 1.5);
end
plot([0 p.L*1e3], [0 0], 'k-', 'LineWidth', 0.5);
xlabel('Distance from clamp (mm)');
ylabel('Normalised deflection');
title('Bending mode shapes');
legend(sprintf('Mode 1 (%.1f Hz)', r.f(1)), sprintf('Mode 2 (%.1f Hz)', r.f(2)), ...
       sprintf('Mode 3 (%.1f Hz)', r.f(3)), 'Location', 'southwest');
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig2_mode_shapes.png'), '-dpng', '-r200');

fprintf('\nFigures saved to %s\n', p.fig_dir);
