clear; close all; clc;

%%  USER INPUT
hull_file = 'kayak.bri';    % Name of the hull geometry file

LCG = 1.53; % Longitudinal centre of gravity [m] (along the hull)
TCG = 0.0;  % Transverse centre of gravity [m] (side-to-side, 0 = centred)
KG  = 2.0;  % Vertical centre of gravity [m] (height above keel)

% Mass sweep (upright, heel = 0)
mass_vector = 10:5:200; % [kg]

% Heel sweep (fixed mass)
heel_deg  = 0:5:90;     % Heel angles [deg] (positive = starboard side down)
heel_mass = 120;        % Fixed total mass for the heel sweep [kg]

%%  FIXED PARAMETERS
rho_water = 1000;  % Water density [kg/m^3]
g = 9.81;          % Gravitational acceleration [m/s^2]

%%  HULL SETUP (origin moved to the CoG)
ship0 = ReadHullGeometry(hull_file);
ship0.x = ship0.x - LCG;
ship0.y = ship0.y - TCG;
ship0.z = ship0.z - KG;
ship0.CoG = [0 0 0];
ship0.KG  = KG;
ship0.LCG = LCG;

state0.rau = rho_water;
state0.g = g;
state0.plotflag = 0;

%%  MASS SWEEP (upright)
Nm = length(mass_vector);
T_m = zeros(1,Nm); Awp_m = zeros(1,Nm); V_m = zeros(1,Nm);

for k = 1:Nm
    [T_m(k), Awp_m(k), V_m(k)] = solveCondition(ship0, state0, mass_vector(k), 0);
end

%%  HEEL SWEEP (fixed mass)
Nh = length(heel_deg);
T_h = zeros(1,Nh); Awp_h = zeros(1,Nh); V_h = zeros(1,Nh); GZ_h = zeros(1,Nh);

for k = 1:Nh
    [T_h(k), Awp_h(k), V_h(k), GZ_h(k)] = solveCondition(ship0, state0, heel_mass, heel_deg(k));
end

%%  RESULTS TABLE - MASS SWEEP
fprintf('\n');
fprintf('Hull file : %s\n', hull_file);
fprintf('LCG = %.2f m  |  TCG = %.2f m  |  KG = %.2f m\n', LCG, TCG, KG);
fprintf('Water density = %.0f kg/m^3\n', rho_water);
fprintf('\n--- Mass sweep (upright, heel = 0 deg) ---\n');
fprintf('%-12s  %-12s  %-21s  %-14s\n', ...
        'Mass [kg]', 'Draught [m]', 'Waterplane area [m^2]', 'Volume [m^3]');
fprintf('%s\n', repmat('-', 1, 62));
for k = 1:Nm
    fprintf('%-12.1f  %-12.4f  %-21.4f  %-14.4f\n', ...
            mass_vector(k), T_m(k), Awp_m(k), V_m(k));
end
fprintf('%s\n', repmat('-', 1, 62));

%%  RESULTS TABLE - HEEL SWEEP
fprintf('\n--- Heel sweep (mass = %.1f kg, volume = %.4f m^3) ---\n', heel_mass, V_h(1));
fprintf('%-12s  %-12s  %-21s  %-10s\n', ...
        'Heel [deg]', 'Draught [m]', 'Waterplane area [m^2]', 'GZ [m]');
fprintf('%s\n', repmat('-', 1, 60));
for k = 1:Nh
    fprintf('%-12.1f  %-12.4f  %-21.4f  %-10.4f\n', ...
            heel_deg(k), T_h(k), Awp_h(k), GZ_h(k));
end
fprintf('%s\n', repmat('-', 1, 60));

%% PLOTS - MASS SWEEP
figure('Name','Hydrostatics vs Mass','NumberTitle','off');

subplot(3,1,1);
plot(mass_vector, T_m, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
xlabel('Mass [kg]'); ylabel('Draught  T  [m]');
title('Draught vs Mass'); grid on;

subplot(3,1,2);
plot(mass_vector, Awp_m, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
xlabel('Mass [kg]'); ylabel('Waterplane area  A_{wp}  [m^2]');
title('Waterplane Area vs Mass'); grid on;

subplot(3,1,3);
plot(mass_vector, V_m, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
xlabel('Mass [kg]'); ylabel('Volume  V  [m^3]');
title('Displaced Volume vs Mass'); grid on;

sgtitle(sprintf('Hydrostatics vs Mass (upright)  –  %s', hull_file), ...
        'FontSize', 12, 'FontWeight', 'bold');

%% PLOTS - HEEL SWEEP
figure('Name','Hydrostatics vs Heel','NumberTitle','off');

subplot(3,1,1);
plot(heel_deg, T_h, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
xlabel('Heel [deg]'); ylabel('Draught  T  [m]');
title('Draught vs Heel'); grid on;

subplot(3,1,2);
plot(heel_deg, Awp_h, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
xlabel('Heel [deg]'); ylabel('Waterplane area  A_{wp}  [m^2]');
title('Waterplane Area vs Heel'); grid on;

subplot(3,1,3);
plot(heel_deg, GZ_h, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
yline(0, 'k--');
xlabel('Heel [deg]'); ylabel('GZ  [m]');
title('Righting Lever vs Heel'); grid on;

sgtitle(sprintf('Hydrostatics vs Heel (m = %.0f kg)  –  %s', heel_mass, hull_file), ...
        'FontSize', 12, 'FontWeight', 'bold');

%%  LOCAL FUNCTION
function [T, Awp, V, GZ] = solveCondition(ship, state, m, heel)
    % Finds vertical equilibrium at a given mass and imposed heel [deg]
    ship.m = m;
    state.eta = [0 0 0 deg2rad(heel) 0 0];   % [X Y Z roll pitch yaw]

    eta3 = fzero(@(e) ForceVertical(e, ship, state), [-8, 8]);
    state.eta(3) = eta3;

    HS = CalculateHydrostatics(ship, state);
    WS = WetSections(ship, state);

    Awp = trapz(ship.x(1,:), WS.bwl);  
    V   = HS.V;
    GZ  = -HS.CoB0(2);                  % G at origin; positive = righting

    % Draught
    [~, ~, Zg] = TransShipfixedGlobal(ship.x, ship.y, ship.z, state.eta);
    valid = (1:size(ship.z,1))' <= ship.np;   % ignore zero-padded offsets
    T = -min(Zg(valid));
end