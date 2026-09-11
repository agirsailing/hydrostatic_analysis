function [F3] = ForceVertical(eta3,ship,state)
    state.eta(3) = eta3;
    [HS] = CalculateHydrostatics(ship,state);
    FB = HS.FB0(3);
    FG = -ship.m*state.g; % Vertical force
    F3 = FB+FG;% Vertical force sum
    %T = ship.KG - state.eta(3) ; % Draught verification
    
end