%% Step 3: sine base excitation response

clear; close all; clc;
load('design_result.mat');
r   = design.res;
mat = design.mat;

free = r.free;
Phi  = r.Phi(free, :);
nf   = numel(free);
rvec = zeros(nf, 1);
rvec(1:2:end) = 1;

omega = 2*pi*r.f;
Gamma = Phi' * r.M * rvec;
m_eff = Gamma.^2;
m_tot = rvec' * r.M * rvec;   % total moving mass (kg)

fprintf('STEP 3: sine response of %s, t = %.1f mm\n', mat.name, design.t*1e3);
fprintf('Damping zeta = %.3f  ->  Q = %.0f  (guide requires 10 <= Q <= 50)\n', ...
        p.zeta, 1/(2*p.zeta));
fprintf('\nMode   f (Hz)   eff. mass (g)   eff. mass (%%)\n');
for j = 1:numel(r.f)
    fprintf('%4d %9.1f %14.1f %14.1f\n', j, r.f(j), m_eff(j)*1e3, m_eff(j)/m_tot*100);
end
fprintf('Sum of listed modes: %.1f %% of total mass %.0f g\n', ...
        sum(m_eff)/m_tot*100, m_tot*1e3);

% Frequency sweep
fr  = linspace(p.sine_f(1), p.sine_f(2), 2000)';
Om  = 2*pi*fr;
a_b = p.sine_level * p.g;

tip_w  = nf - 1;
w2_dof = 1;  th2_dof = 2;
Le = r.Le;

acc_tip  = zeros(size(fr));
sig_root = zeros(size(fr));
for k = 1:numel(fr)
    H = 1 ./ (omega.^2 - Om(k)^2 + 2i*p.zeta*omega*Om(k));   % modal FRF
    q = -Gamma .* H * a_b;   % modal coordinates
    u = Phi * q;   % relative displacements
    acc_tip(k) = abs(a_b - Om(k)^2 * u(tip_w));
    kappa = (6*u(w2_dof) - 2*Le*u(th2_dof)) / Le^2;
    sig_root(k) = abs(mat.E * kappa * design.t/2);
end
T = acc_tip / a_b;   % transmissibility

[Tmax, kmax] = max(T);
[sig_max, ks] = max(sig_root);

fprintf('\nInput: %.1f g from %.0f to %.0f Hz (unit input)\n', ...
        p.sine_level, p.sine_f(1), p.sine_f(2));
fprintf('Peak transmissibility at tip: %.1f at %.1f Hz\n', Tmax, fr(kmax));
fprintf('Peak tip acceleration:        %.1f g\n', Tmax*p.sine_level);
fprintf('Peak root bending stress:     %.1f MPa at %.1f Hz\n', sig_max/1e6, fr(ks));
FS = 1.25;
MS = mat.sigma_y / (FS * sig_max) - 1;
if MS > 0, ms_txt = 'OK'; else, ms_txt = 'FAILS'; end
fprintf('Margin of safety (FS = %.2f on yield %.0f MPa): MS = %.2f  (%s)\n', ...
        FS, mat.sigma_y/1e6, MS, ms_txt);

% Figure 5: transmissibility
c1 = [0.165 0.471 0.839];
fig = figure('Position', [100 100 640 440]);
semilogy(fr, T, '-', 'Color', c1, 'LineWidth', 1.5); hold on;
semilogy([p.f_req p.f_req], [0.5 100], 'k--', 'LineWidth', 1);
ylim([0.5 100]);
xlabel('Excitation frequency (Hz)');
ylabel('Tip acceleration / base acceleration');
title(sprintf('Sine response, Q = %.0f', 1/(2*p.zeta)));
legend('Panel tip', 'Requirement 40 Hz', 'Location', 'northwest');
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig5_transmissibility.png'), '-dpng', '-r200');

% Figure 6: root stress
fig = figure('Position', [100 100 640 440]);
plot(fr, sig_root/1e6, '-', 'Color', c1, 'LineWidth', 1.5); hold on;
xlabel('Excitation frequency (Hz)');
ylabel('Bending stress at clamp (MPa)');
title(sprintf('Root stress for %.1f g sine input', p.sine_level));
grid on; box on;
print(fig, fullfile(p.fig_dir, 'fig6_root_stress.png'), '-dpng', '-r200');

fprintf('\nFigures saved to %s\n', p.fig_dir);
