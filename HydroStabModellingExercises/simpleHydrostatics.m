clear all; close all;

%%  USER INPUT 
hull_file = 'kayak.bri';    % Name of the hull geometry file

LCG = 5.8;  % Longitudinal centre of gravity [m] (along the hull)
TCG = 0.0;  % Transverse centre of gravity [m] (side-to-side, 0 = centred)
KG = 2.0;   % Vertical centre of gravity [m] (height above keel)

% Mass range to evaluate
mass_min = 0.01;    % Minimum total mass [kg]
mass_max = 200;   % Maximum total mass [kg]
mass_step = 9.09;   % Step between masses [kg]

%%  FIXED PARAMETERS 
rho_water = 1025;  % Water density [kg/m^3]  
g = 9.81;          % Gravitational acceleration [m/s^2]

[ship0] = ReadHullGeometry(hull_file);

mass_vector = mass_min : mass_step : mass_max;
N = length(mass_vector);

% Pre-allocate result arrays
T_vec = zeros(1, N);   % Draught [m]
Awp_vec = zeros(1, N); % Waterplane area [m^2]
V_vec = zeros(1, N);   % Displaced volume [m^3]

%%  MAIN LOOP
for k = 1:N
    m = mass_vector(k);

    ship = ship0;
    ship.m = m;
    ship.CoG = [LCG, TCG, KG];
    ship.KG = KG;
    ship.LCG = LCG;

    ship.x = ship.x-LCG; ship.CoG(1) = 0;
    ship.y = ship.y-TCG; ship.CoG(2) = 0;
    ship.z = ship.z-KG; ship.CoG(3) = 0;

    state.rau = rho_water;
    state.g = g;
    state.plotflag = 0;
    state.eta = [0 0 0 0 0 0];   % [X Y Z roll pitch yaw]
    state.eta(4) = 0;            % heel = 0 (upright)

    % find the vertical equilibrium draught with fzero
    [eta3_eq, ~] = fzero(@(e) ForceVertical(e, ship, state), [-8, 8]);
    state.eta(3) = eta3_eq;

    % compute hydrostatics at equilibrium
    HS = CalculateHydrostatics(ship, state);
    T_vec(k) = KG-eta3_eq;

    WS = WetSections(ship, state);
    x_vec = ship.x(1,:);
    Awp_vec(k) = 2*trapz(x_vec, WS.bwl);   

    V_vec(k) = HS.V; 
end

%%  RESULTS TABLE
fprintf('\n');
fprintf('Hull file : %s\n', hull_file);
fprintf('LCG = %.2f m  |  TCG = %.2f m  |  KG = %.2f m\n', LCG, TCG, KG);
fprintf('Water density = %.0f kg/m^3\n', rho_water);
fprintf('\n');
fprintf('%-12s  %-12s  %-18s  %-14s\n', ...
        'Mass [kg]', 'Draught [m]', 'Waterplane area [m^2]', 'Volume [m^3]');
fprintf('%s\n', repmat('-', 1, 62));
for k = 1:N
    fprintf('%-12.1f  %-12.4f  %-21.4f  %-14.4f\n', ...
            mass_vector(k), T_vec(k), Awp_vec(k), V_vec(k));
end
fprintf('%s\n', repmat('-', 1, 62));

%% PLOTS
figure('Name','Hydrostatics vs Mass','NumberTitle','off');

subplot(3,1,1);
plot(mass_vector, T_vec, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
xlabel('Mass [kg]');
ylabel('Draught  T  [m]');
title('Draught vs Mass');
grid on;

subplot(3,1,2);
plot(mass_vector, Awp_vec, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
xlabel('Mass [kg]');
ylabel('Waterplane area  A_{wp}  [m^2]');
title('Waterplane Area vs Mass');
grid on;

subplot(3,1,3);
plot(mass_vector, V_vec, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
xlabel('Mass [kg]');
ylabel('Volume  V  [m^3]');
title('Displaced Volume vs Mass');
grid on;

sgtitle(sprintf('Hydrostatics  –  %s', hull_file), 'FontSize', 12, 'FontWeight', 'bold');