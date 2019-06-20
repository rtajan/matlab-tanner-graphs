# matlab-tanner-graphs short presentation

matlab-tanner-graphs is a tool written in Matlab for displaying, editing and exporting Tanner graphs.
It is easy to use, the Tanner graph is created directly from the parity check matrix.

# Using matlab-tanner-graphs
For creating a Tanner graph for the Hamming, just type the following code in Matlab :
```matlab
H = [1 0 1 0 1 0 1; 0 1 1 0 0 1 1; 0 0 0 1 1 1 1]; % Hamming parity check matrix
tg = tanner_graph(H);                              % Build Tanner graph
plot(tg)                                           % Display Tanner graph
```
The expected output should be this Tanner graph :

![Hamming_screenshot](https://user-images.githubusercontent.com/20512172/59837477-9bf80b80-934d-11e9-9942-7a5cbcf5893a.png)

Now you can edit this graph by grabbing the nodes and moving them. 

Also, if you want to export the graph to a latex file (Tikz picture), just type the following code in Matlab
```matlab
H = [1 0 1 0 1 0 1; 0 1 1 0 0 1 1; 0 0 0 1 1 1 1]; % Hamming parity check matrix
tg = tanner_graph(H);                              % Build Tanner graph
h_tg = plot(tg);                                   % Display Tanner graph and get a handle to it
% Move nodes, if you want to
h_tg.to_tikz('hamming.tex');                       % Export to a latex file
```
After compiling hamming.tex with pdflatex you should have :

![Hamming Tikz](https://user-images.githubusercontent.com/20512172/59837506-a74b3700-934d-11e9-9066-fc3d8da9c460.png)
