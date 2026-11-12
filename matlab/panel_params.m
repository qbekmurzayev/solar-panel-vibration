function p = panel_params()
% input data, SI units

p.f_req      = 40;
p.margin     = 0.10;
p.f_target   = p.f_req * (1 + p.margin);

p.L          = 0.30;
p.b          = 0.10;   % m, width

p.m_tip      = 0.050;   % kg

p.mat(1).name    = 'Al 6061-T6';
p.mat(1).E       = 68.9e9;   % Pa
p.mat(1).rho     = 2700;   % kg/m^3
p.mat(1).nu      = 0.33;
p.mat(1).sigma_y = 276e6;   % Pa, yield strength

p.mat(2).name    = 'CFRP quasi-iso';
p.mat(2).E       = 50e9;   % Pa
p.mat(2).rho     = 1550;   % kg/m^3
p.mat(2).nu      = 0.30;
p.mat(2).sigma_y = 400e6;

p.design_mat = 1;

p.sw.t_face   = 0.3e-3;   % m, each face sheet
p.sw.rho_core = 50;
p.sw.m_glue   = 0.15;

p.t_available = [1.0 1.6 2.0 2.5 3.0 4.0 5.0 6.0] * 1e-3;

% Dynamics
p.zeta       = 0.02;
p.n_el       = 40;
p.n_modes    = 4;   % modes to keep

p.g          = 9.80665;
p.sine_f     = [5 100];   % Hz
p.sine_level = 1.0;   % g

p.fig_dir    = fullfile('..', 'figures');
end
