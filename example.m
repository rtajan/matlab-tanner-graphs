clear
clc
close all

H = [1 0 1 0 1 0 1;0 1 1 0 0 1 1;0 0 0 1 1 1 1]; % The parity check matrix for Hamming code


tg = tanner_graph(H); % Building the Tanner graph
plot(tg) % Display the Tanner graph

tg.to_tikz('hamming.tex'); % Export to Tikz