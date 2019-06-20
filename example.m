clear
clc
close all

H = de2bi(1:7,3)'; % The parity check matrix for Hamming code
tg = tanner_graph(H); % Building the Tanner graph
plot(tg) % Display the Tanner graph

h_tg = plot(tg); % Get a handle to the Tanner graph
h_tg.to_tikz('hamming.tex'); % Export to Tikz