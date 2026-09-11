%% Convert a hull STL mesh to a britfair (.bri) section file

%% LOAD THE STL FILE
[file, path] = uigetfile('*.stl', 'Select the STL file');
if isequal(file, 0)
    return; 
end          

tr = stlread(fullfile(path, file));   % read triangulated surface
coords = unique(tr.Points, 'rows');   % remove duplicate vertices
coords = coords / 1000;


%%  ORIENT THE HULL
if mean(coords(:,1)) < 0
    coords(:,1) = coords(:,1)*(-1);
end

% Shift so that the aftmost point is at X = 0
coords(:,1) = coords(:,1)-min(coords(:,1));

% The STL Z-axis sometimes points downward; flip so keel is at bottom
coords(:,3) = coords(:,3)*(-1);

% Shift so keel is at Z = 0
coords(:,3) = coords(:,3)-min(coords(:,3));

%% KEEP ONE SIDE OF THE HULL ONLY
coords(abs(coords(:,2)) < 0.005, 2) = 0;
coords = coords(coords(:,2) >= 0, :);

%% EXPORT RAW COORDINATES TO CSV
writetable(table(coords(:,1), coords(:,2), coords(:,3), ...
    'VariableNames', {'X','Y','Z'}), 'kayak.csv');

%% GROUP POINTS INTO CROSS-SECTIONS BY X POSITION
x_rounded = round(coords(:,1), 3);
unique_x = unique(x_rounded, 'sorted');   % one entry per frame station

%  WRITE THE .BRI FILE
fid = fopen('kayak.bri', 'wt');
fprintf(fid, 'Kayak\n1\n');   

for i = 1:length(unique_x)

    current_x = unique_x(i);
    idx = (x_rounded == current_x);
    section_pts = coords(idx, 2:3);          % [Y, Z] for this section

    % Sort points from keel
    [~, sortIdx] = sort(section_pts(:,2));  % sort by Z ascending
    section_pts = section_pts(sortIdx, :);

    num_pts = size(section_pts, 1);

    fprintf(fid, '%d %.6f %.6f\n', num_pts, current_x, current_x);

    for p = 1:num_pts
        fprintf(fid, '%.6f %.6f\n', section_pts(p,1), section_pts(p,2));
    end

    fprintf(fid, '0\n');   % section terminator required by the format
end

fprintf(fid, '0 0 0\n');   % file terminator
fclose(fid);

%% VISUAL CHECK
figure;
scatter3(coords(:,1), coords(:,2), coords(:,3), 5, coords(:,3), 'filled');
colorbar;
xlabel('X  (longitudinal) [m]');
ylabel('Y  (transverse)   [m]');
zlabel('Z  (vertical)     [m]');
axis equal; grid on;
title('Hull half cross-sections');

disp('.bri ready.');