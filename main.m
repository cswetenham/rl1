%% Design

% Firstly, since we are working in Matlab, we will not attempt to abstract
% over the details of the problem and produce a general algorithm, since
% the facilities available for doing so are relatively limited. Instead we
% will specify the problem and its representation and then write algorithms
% that solve the specific problem. That said, we will abstract a little
% where it is useful for code reuse between similar code for our
% algorithms.

% In some places we will make use of the fact that we have a tabular
% representation of a function, to speed up the algorithm; in others we
% will allow for a function to be either represented as a Matlab table or
% as a Matlab function, which will be either called or indexed with the
% same syntax, e.g. Q(S, A).

%% Setup

clc;
clear all;
close all;

%% Part I - gridworld, dynamic programming

Rot90 = [
     0 +1;
    -1  0
];

% Action representation: Idx mapped to dX, dY by this tablestateFromPos = @(P) sub2ind(MapSize, P(1), P(2));
Actions = [
    +1  0; % 1 E >
     0 -1; % 2 S V
    -1  0; % 3 W <
     0 +1; % 4 N ^
];
NActions = size(Actions, 1);

MapWidth = 8;
MapHeight = 8;
MapSize = [MapWidth MapHeight];
NStates = prod(MapSize);
GoalState = NStates;

stateFromPos = @(P) (P(1) - 1) + MapWidth * (P(2) - 1) + 1;
posFromState = @(S) [mod((S - 1),MapWidth) + 1, floor((S - 1)/MapWidth) + 1];


%% Walls
% Horizontal wall representation: Y, StartX, EndX
Walls_H = [
    0.5, 0.5, 8.5;
    1.5, 0.5, 1.5;
    1.5, 7.5, 8.5;
    5.5, 3.5, 5.5;
    6.5, 2.5, 6.5;
    8.5, 0.5, 8.5
];

% Vertical wall representation: X, StartY, EndY
Walls_V = [
    0.5, 0.5, 8.5;
    2.5, 4.5, 6.5;
    3.5, 3.5, 5.5;
    4.5, 2.5, 4.5;
    5.5, 3.5, 5.5;
    6.5, 4.5, 6.5;
    8.5, 0.5, 8.5
];

% Compute state transition matrix from walls

% [State x Action] -> State
StateTransitions = zeros([NStates, NActions]);

for A = 1:NActions
    for S = 1:NStates
        P = posFromState(S);
        
        X = P(1);
        Y = P(2);
        NP = Actions(A,:) + P;
        MoveOK = 1;
        
        for W = 1:size(Walls_H, 1)
            WS = [Walls_H(W, 2) Walls_H(W, 1)];
            WE = [Walls_H(W, 3) Walls_H(W, 1)];
            MoveOK = MoveOK & ~testSegmentSegment(P, NP, WS, WE);
        end
        
        for W = 1:size(Walls_V, 1)
            WS = [Walls_V(W, 1) Walls_V(W, 2)];
            WE = [Walls_V(W, 1) Walls_V(W, 3)];
            MoveOK = MoveOK & ~testSegmentSegment(P, NP, WS, WE);
        end
        
        if (MoveOK)
            StateTransitions(S, A) = stateFromPos(NP);
        else
            StateTransitions(S, A) = S;
        end
    end
end

StateTransitions(GoalState, :) = repmat(GoalState, [NActions 1]);

% Policy representation: [State] -> Action
% from the goal state
StartPolicy = [
    1 4 4 4 4 4 4 3 ...
    1 4 4 1 1 1 4 3 ...
    1 4 4 2 4 3 4 3 ...
    1 1 4 2 4 2 4 3 ...
    1 2 4 2 3 2 4 3 ...
    1 2 1 1 1 2 1 4 ...
    1 2 3 3 1 1 2 4 ...
    1 2 3 3 1 1 2 4
]';

% Arrows for rendering state transitions
Arrow(1, :, :) = [
    0.25 0;
    0.75 0;
    0.625 -0.125;
    0.75 0;
    0.625 +0.125;
    0.75 0;
];
% Rotate for other directions
for A = 2:4
    for L = 1:size(Arrow, 2)
        Arrow(A,L,:) = Rot90^(A-1) * squeeze(Arrow(1,L,:));
    end
end

% Arrows for rendering policies
% TODO make X/Y component the last, the remove the squeeze()
% TODO remove the transpose
% TODO generate with rotation matrix
% 0 G X
ActionGlyphs(1, 1, :, :) = [-1 +1; -1 +1]';
ActionGlyphs(2, 1, :, :) = [-1 +1; +1 -1]';
% 1 E >
ActionGlyphs(1, 2, :, :) = [-1 +1; -1 +1]';
ActionGlyphs(2, 2, :, :) = [+1  0; -1  0]';
% 2 S V
ActionGlyphs(1, 3, :, :) = [-1  0; +1  0]';
ActionGlyphs(2, 3, :, :) = [+1 -1; +1 -1]';
% 3 W < 
ActionGlyphs(1, 4, :, :) = [+1 -1; +1 -1]';
ActionGlyphs(2, 4, :, :) = [+1  0; -1  0]';
% 4 N ^
ActionGlyphs(1, 5, :, :) = [-1  0; +1  0]';
ActionGlyphs(2, 5, :, :) = [-1 +1; -1 +1]';
% Rescale
ActionGlyphs = 0.25 * ActionGlyphs;

drawWalls = @() drawWalls(Walls_H, Walls_V);
drawStateTransitions = @(StateTransitions) drawStateTransitions(Arrow, StateTransitions, posFromState);
drawPolicy = @(Policy) drawPolicy(ActionGlyphs, Policy, posFromState);

figure;
    drawWalls();
    drawStateTransitions(StateTransitions);
    drawPolicy(StartPolicy);
axis([0.5, 8.5, 0.5, 8.5], 'xy', 'square');

%% TODO - implement state transition probs PP(a, s, s') as a function that
%% PP(s, a) -> [States, Probs]; a list of non-zero next states and their
%% probabilities? Or PP(s, a, rnd) -> new state at random according to
%% distribution

reward = @(S, A, S2) -1 * (S ~= GoalState);

Discount = 1;
MaxIterations = 1000;
MaxPolicyIterations = 1000;
Policy = StartPolicy;
for PP = 1:MaxPolicyIterations
    % Evaluate policy
    V = evaluatePolicy(Policy, StateTransitions, reward, Discount, MaxIterations);

    % Compute greedy policy
    NewPolicy = improvePolicy(V, StateTransitions, reward, Discount);
    if (all(Policy == NewPolicy))
        break;
    end
    Policy = NewPolicy;
    
    figure(2);
        imagesc(reshape(V, MapSize));
        colormap('gray');
        drawWalls();
        drawPolicy(Policy);
    axis([0.5, 8.5, 0.5, 8.5], 'xy', 'square');
    
    refresh;
    pause(0.1);
end
fprintf('Iterations before policy convergence: %d\n', PP);
%input('Paused...');
% Value iteration
Policy = StartPolicy;
MaxIterations = 1;
Discount = 1;
MaxPolicyIterations = 1000;
V = zeros([NStates 1]);
for PP = 1:MaxPolicyIterations
    % Evaluate policy
    % V = evaluatePolicy(Policy, StateTransitions, reward, Discount, MaxIterations);

    % Compute greedy policy
    % NewPolicy = improvePolicy(V, StateTransitions, reward, Discount);
    NewV = valueIteration(V, StateTransitions, reward, Discount);
    if (all(V == NewV))
        break;
    end
    V = NewV;
    
    Policy = improvePolicy(V, StateTransitions, reward, Discount);
    
    figure(3);
        imagesc(reshape(V, MapSize));
        colormap('gray');
        drawWalls();
        drawPolicy(Policy);
    axis([0.5, 8.5, 0.5, 8.5], 'xy', 'square');
    
    refresh;
    pause(0.1);
end
fprintf('Iterations before policy convergence: %d\n', PP);

%% Part II - secretary problem, MC, TD (Q-learning)