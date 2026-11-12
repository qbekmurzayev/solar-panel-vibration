%% Step 2: panel thickness for 40 Hz

clear; close all; clc;
p = panel_params();
if ~exist(p.fig_dir, 'dir'), mkdir(p.fig_dir); end

t_sweep = linspace(1.0e-3, 6.0e-3, 51);
nm = numel(p.mat);
f1   = zeros(nm, numel(t_sweep));
mass = zeros(nm, numel(t_sweep));

for i = 1:nm
    mat = p.mat(i);
    for k = 1:numel(t_sweep)
        t = t_sweep(k);
        I = p.b * t^3 / 12;
        rhoA = mat.rho * p.b * t;
        r = beam_fem(p.L, mat.E, I, rhoA, p.m_tip, p.n_el, 1);
        f1(i, k)   = r.f(1);
        mass(i, k) = rhoA * p.L;
    end
end

fprintf('STEP 2: design study (L = %.0f mm, b = %.0f mm, tip mass = %.0f g)\n', ...
        p.L*1e3, p.b*1e3, p.m_tip*1e3);
fprintf('Requirement f1 >= %.0f Hz, design target with %.0f%% margin: %.1f Hz\n\n', ...
        p.f_req, p.margin*100, p.f_target);

fprintf('%-16s %8s %10s %10s %12s %8s\n', 'Material', 't (mm)', 'f1 FEM', ...
        'f1 hand', 'mass (g)', 'OK?');
best = struct('i', 0, 't', 0, 'f1', 0, 'mass', inf);
for i = 1:nm
    mat = p.mat(i);
    for t = p.t_available
        I = p.b * t^3 / 12;
        rhoA = mat.rho * p.b * t;
        r = beam_fem(p.L, mat.E, I, rhoA, p.m_tip, p.n_el, 1);
        m_panel = rhoA * p.L;
        % % Hand check (Rayleigh, cantilever + tip mass)
        f_hand = sqrt(3*mat.E*I / (p.L^3 * (p.m_tip + 0.2357*m_panel))) / (2*pi);
        ok = r.f(1) >= p.f_target;
        if ok, ok_txt = 'yes'; else, ok_txt = 'no'; end
        fprintf('%-16s %8.1f %10.2f %10.2f %12.1f %8s\n', mat.name, t*1e3, ...
                r.f(1), f_hand, m_panel*1e3, ok_txt);
        if ok && i == p.design_mat && m_panel < best.mass
            best = struct('i', i, 't', t, 'f1', r.f(1), 'mass', m_panel);
        end
    end
    fprintf('\n');
end

% Chosen design
mat = p.mat(best.i);
I = p.b * best.t^3 / 12;
rhoA = mat.rho * p.b * best.t;
r = beam_fem(p.L, mat.E, I, rhoA, p.m_tip, p.n_el, p.n_modes);

f1_plate = r.f(1) / sqrt(1 - mat.nu^2);

fprintf('CHOSEN DESIGN: %s, t = %.1f mm, panel mass = %.0f g (+ %.0f g tip)\n', ...
        mat.name, best.t*1e3, best.mass*1e3, p.m_tip*1e3);
fprintf('  Bending modes (beam FEM): %s Hz\n', sprintf('%.1f  ', r.f));
fprintf('  Expected f1 in ANSYS: between %.1f Hz (beam) and %.1f Hz (wide plate)\n', ...
        r.f(1), f1_plate);
fprintf('  Margin over requirement: %.0f%%\n', (r.f(1)/p.f_req - 1)*100);
fprintf('  ANSYS will also show torsion modes, which the beam model cannot.\n');

design.mat = mat; design.t = best.t; design.I = I; design.rhoA = rhoA;
design.res = r; design.f1_plate = f1_plate;
save('design_result.mat', 'design', 'p');

% Figure 3: f1 vs thickness
c = [0.165 0.471 0.839; 0.922 0.408 0.204];
fig = figure('Position', [100 100 640 440]);
hold on;
for i = 1:nm
    plot(t_sweep*1e3, f1(i,:), '-', 'Color', c(i,:), 'LineWidth', 1.5);
end
plot(t_sweep([1 end])*1e3, [p.f_req p.f_req], 'k--', 'LineWidth', 1);
plot(t_sweep([1 end])*1e3, [p.f_target p.f_target], 'k:', 'LineWidth', 1);
plot(best.t*1e3, best.f1, 'o', 'Color', c(best.i,:), 'MarkerSize', 8, ...
     'MarkerFaceColor', c(best.i,:));
xlabel('Panel thickness (mm)');
ylabel('First natural frequency f_1 (Hz)');
title('First natural frequency vs thickness');
legend(p.mat(1).name, p.mat(2).name, 'Requirement 40 Hz', ...
       'Target 44 Hz (+10%)', 'Chosen design', 'Location', 'northwest');
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig3_f1_vs_thickness.png'), '-dpng', '-r200');

% Figure 4: the trade-off, f1 vs mass
fig = figure('Position', [100 100 640 440]);
hold on;
for i = 1:nm
    plot(mass(i,:)*1e3, f1(i,:), '-', 'Color', c(i,:), 'LineWidth', 1.5);
end
plot([0 max(mass(:))*1e3], [p.f_req p.f_req], 'k--', 'LineWidth', 1);
plot(best.mass*1e3, best.f1, 'o', 'Color', c(best.i,:), 'MarkerSize', 8, ...
     'MarkerFaceColor', c(best.i,:));
xlabel('Panel mass without tip mass (g)');
ylabel('First natural frequency f_1 (Hz)');
title('Stiffness vs mass trade-off');
legend(p.mat(1).name, p.mat(2).name, 'Requirement 40 Hz', 'Chosen design', ...
       'Location', 'southeast');
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig4_f1_vs_mass.png'), '-dpng', '-r200');

fprintf('\nFigures saved to %s\n', p.fig_dir);
