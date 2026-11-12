%% Step 4: ANSYS vs MATLAB

clear; close all; clc;
p = panel_params();
load('design_result.mat');   % 'design' from step 2

h_mesh = [10 5 3 2];   % element size (mm)
f_ansys = [46.885 305.10 333.81 715.86 876.71 1049.2;
           46.782 304.39 333.38 715.66 874.63 1047.7;
           46.707 303.85 332.55 715.54 872.79 1044.9;
           46.696 303.77 332.47 715.47 872.55 1044.7];
mode_type = {'1st out-of-plane bending', '2nd out-of-plane bending', ...
             '1st torsion', '1st in-plane bending', ...
             '3rd out-of-plane bending', '2nd torsion (assumed, shape not checked)'};

% Mesh convergence
fprintf('STEP 4: ANSYS mesh convergence (change vs finest mesh, 2 mm)\n');
fprintf('%-10s', 'size (mm)');
fprintf('%11s', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6');
fprintf('\n');
for k = 1:numel(h_mesh)
    fprintf('%-10d', h_mesh(k));
    fprintf('%11.2f', f_ansys(k, :));
    fprintf('\n');
end
dev = (f_ansys - f_ansys(end, :)) ./ f_ansys(end, :) * 100;
fprintf('\nChange vs 2 mm (%%):\n');
for k = 1:numel(h_mesh)-1
    fprintf('%-10d', h_mesh(k));
    fprintf('%11.3f', dev(k, :));
    fprintf('\n');
end
fprintf('3 mm -> 2 mm change in f1: %.3f %%  (criterion < 1 %%: converged)\n', ...
        abs(dev(3,1)));

f_beam  = design.res.f(1:3)';
nu      = design.mat.nu;
f_plate = f_beam / sqrt(1 - nu^2);
fa      = f_ansys(end, [1 2 5]);

fprintf('\nBending modes: ANSYS (2 mm) vs MATLAB\n');
fprintf('%-28s %10s %10s %10s %10s\n', 'Mode', 'ANSYS', 'Beam', 'Plate bnd', 'ANSYS-Beam');
idx = [1 2 5];
for j = 1:3
    fprintf('%-28s %10.2f %10.2f %10.2f %9.2f%%\n', mode_type{idx(j)}, fa(j), ...
            f_beam(j), f_plate(j), (fa(j)/f_beam(j) - 1)*100);
end

fprintf('\nAll ANSYS modes (2 mm mesh):\n');
for j = 1:6
    fprintf('  Mode %d: %8.2f Hz  %s\n', j, f_ansys(end, j), mode_type{j});
end
fprintf('\nRequirement check: f1 = %.2f Hz >= %.0f Hz  ->  margin %.1f %%\n', ...
        f_ansys(end,1), p.f_req, (f_ansys(end,1)/p.f_req - 1)*100);

% Figure 8: convergence of f1
c = [0.165 0.471 0.839; 0.922 0.408 0.204];
fig = figure('Position', [100 100 640 440]);
plot(h_mesh, f_ansys(:,1), '-o', 'Color', c(1,:), 'LineWidth', 1.5, ...
     'MarkerSize', 6, 'MarkerFaceColor', c(1,:)); hold on;
plot([1.5 10.5], f_beam(1)*[1 1], '--', 'Color', c(2,:), 'LineWidth', 1.5);
plot([1.5 10.5], f_plate(1)*[1 1], ':', 'Color', c(2,:), 'LineWidth', 1.5);
set(gca, 'XDir', 'reverse');
xlim([1.5 10.5]);
xlabel('Element size (mm)');
ylabel('First natural frequency f_1 (Hz)');
title('ANSYS mesh convergence vs MATLAB beam model');
legend('ANSYS solid model', 'MATLAB beam FEM', 'Beam with plate correction', ...
       'Location', 'east');
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig8_ansys_convergence.png'), '-dpng', '-r200');
fprintf('\nFigure saved to %s\n', p.fig_dir);
