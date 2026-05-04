%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Wing Geometry Plotting Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [maxx, miny, maxy] = plot_wing(span_length, root_chord, taper, sweep, LW, color, LO)
% Calculate wing parameters
span_length = span_length * 2;
% tip_chord = taper * root_chord;  % Uncomment if tip chord is needed
sweep = deg2rad(sweep);
AR = 2 * span_length / (root_chord * (1 + taper));
tan_LE = (sweep + (1 - taper) / (AR * (1 + taper)));
tan_TE = (tan_LE - 4 * (1 - taper) / (AR * (1 + taper)));

% Determine main wing points
x1 = [0, 0];
y1 = [0, root_chord];

x2 = [span_length/2, span_length/2];
y2 = [root_chord - span_length/2 * tan_LE, -span_length/2 * tan_TE];

x3 = [0, span_length/2];
y3 = [root_chord, root_chord - span_length/2 * tan_LE];

x4 = [0, span_length/2];
y4 = [0, -span_length/2 * tan_TE];

maxx = span_length;
miny = min([min(y1), min(y2), min(y3), min(y4)]);
maxy = max([max(y1), max(y2), max(y3), max(y4)]);

% Plot the wing geometry (view from above)
figure(1);
plot(x1, y1, "Color", color, "LineWidth", LW, "LineStyle", LO);
ylabel('Chord Length (m)');
hold on;
plot(x2, y2, "Color", color, "LineWidth", LW, "LineStyle", LO, "HandleVisibility", "off");
plot(x3, y3, "Color", color, "LineWidth", LW, "LineStyle", LO, "HandleVisibility", "off");
plot(x4, y4, "Color", color, "LineWidth", LW, "LineStyle", LO, "HandleVisibility", "off");

xlabel('Span (m)');
title('Wing Geometry (Plan View)');
axis equal;
grid on;
grid minor;
hold off;
end