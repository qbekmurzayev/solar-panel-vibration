function [f1, m_panel, EI, rhoA] = sandwich_f1(hc, tf, Ef, rho_f, p)
% first frequency and mass of sandwich panel

d    = hc + tf;
EI   = Ef * p.b * tf * d^2 / 2;
rhoA = p.b * (2*tf*rho_f + hc*p.sw.rho_core + p.sw.m_glue);
r    = beam_fem(p.L, Ef, EI/Ef, rhoA, p.m_tip, p.n_el, 1);
f1   = r.f(1);
m_panel = rhoA * p.L;
end
