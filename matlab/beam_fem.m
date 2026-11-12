function out = beam_fem(L, E, I, rhoA, m_tip, n_el, n_modes)
% cantilever beam FEM (Euler-Bernoulli), returns f, mode shapes, M, K

Le   = L / n_el;
nn   = n_el + 1;   % number of nodes
ndof = 2 * nn;

% Element stiffness matrix (Hermite cubic beam element)
ke = E*I/Le^3 * [ 12     6*Le    -12     6*Le;
                  6*Le   4*Le^2  -6*Le   2*Le^2;
                 -12    -6*Le     12    -6*Le;
                  6*Le   2*Le^2  -6*Le   4*Le^2];

% Consistent element mass matrix
me = rhoA*Le/420 * [ 156     22*Le    54     -13*Le;
                     22*Le   4*Le^2   13*Le  -3*Le^2;
                     54      13*Le    156    -22*Le;
                    -13*Le  -3*Le^2  -22*Le   4*Le^2];

% Assembly
K = zeros(ndof);
M = zeros(ndof);
for e = 1:n_el
    dofs = 2*e-1 : 2*e+2;
    K(dofs, dofs) = K(dofs, dofs) + ke;
    M(dofs, dofs) = M(dofs, dofs) + me;
end

% Tip mass acts on the deflection DOF of the last node
M(ndof-1, ndof-1) = M(ndof-1, ndof-1) + m_tip;

% Clamp at node 1: remove DOFs 1 and 2
free = 3:ndof;
Kf = K(free, free);
Mf = M(free, free);

% Generalised eigenvalue problem  K*phi = omega^2 * M*phi
[V, D] = eig(Kf, Mf);
[lam, idx] = sort(diag(D));
V = V(:, idx);

n_modes = min(n_modes, numel(lam));
lam = lam(1:n_modes);
V   = V(:, 1:n_modes);

% Mass-normalise: phi' * M * phi = 1
for j = 1:n_modes
    V(:, j) = V(:, j) / sqrt(V(:, j)' * Mf * V(:, j));
    % % sign convention: tip deflection positive
    if V(end-1, j) < 0
        V(:, j) = -V(:, j);
    end
end

Phi = zeros(ndof, n_modes);
Phi(free, :) = V;

out.f    = sqrt(lam) / (2*pi);
out.Phi  = Phi;
out.x    = linspace(0, L, nn)';
out.M    = Mf;
out.K    = Kf;
out.free = free;
out.Le   = Le;
end
