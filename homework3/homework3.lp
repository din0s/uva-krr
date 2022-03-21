%*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% KRR 2022, HOMEWORK ASSIGNMENT 3 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Name:             Konstantinos Papakostas
Student number:   13914332

Name:             Apostolos Panagiotopoulos
Student number:   14021900

*%

%*
INPUT REPRESENTATION:
- Represent the input of the problem (the map, the trucks, etc.)

[EXPLAIN YOUR CODE USING SHORT INLINE COMMENTS (SEE EXAMPLE BELOW)]
*%

% Represent the nodes and edges of the map using node/1 and edge/2.
node(1..13).
edge(1,3 ; 1,4 ;
     2,4 ; 2,5 ;
     3,4 ; 3,7 ;
     4,5 ; 4,7 ; 4,8 ;
     5,6 ; 5,8 ; 5,9 ;
     6,10 ;
     7,8 ; 7,11 ;
     8,9 ;
     9,10 ;
     10,13 ;
     11,12 ;
     12,13
    ).

% Edges are undirected, so include their reverse
edge(X,Y) :- edge(Y,X).

% charging_station(NODE_ID)
charging_station(1;2).

% delivery_point(NODE_ID)
delivery_point(3;6).

% warehouse(NODE_ID)
warehouse(10).

% parking(NODE_ID)
parking(11..13).

% truck(TRUCK_ID,BATTERY_CAPACITY,PACKAGE_CAPACITY)
truck(t1,10,1 ; t2,10,2 ; t3,10,3).

%*
TIME STEPS:
- Represent the different time steps (up to some upper bound)

[EXPLAIN YOUR CODE USING SHORT INLINE COMMENTS]
*%

#const t=25. % This is an upper bound on the number of time steps needed

% All possible time steps
valid_time(1..t).

% Choose a sequence of time steps
{ time(T) : valid_time(T) }.

% Start at time 1
:- not time(1).

% Ensure time steps are picked in ascending order
:- valid_time(T), valid_time(T+1), time(T+1), not time(T).

% Max time is the last time step
max_time(MT) :- MT = #max { T : time(T) }.

%*
ACTIONS:
- Represent the possible actions that each truck can take

[EXPLAIN YOUR CODE USING SHORT INLINE COMMENTS]
*%

% Define all possible actions
action(wait;load;unload;charge).
action(move(NID)) :- node(NID).

%*
GENERATE A SEQUENCE OF ACTIONS:
- Generate a sequence of actions (for each truck)

[EXPLAIN YOUR CODE USING SHORT INLINE COMMENTS]
*%

% For each time step (except for the final one), each truck does exactly one action
1 { do(T,TID,A) : action(A) } 1 :- time(T), truck(TID,_,_), max_time(MT), T < MT.

%*
INITIAL STATE:
- Encode the initial state

[EXPLAIN YOUR CODE USING SHORT INLINE COMMENTS]
*%

% Syntax: state(TIME,STATE)
% States: truck_at(TRUCK_ID,NODE_ID), truck_battery(TRUCK_ID,BATTERY_LEVEL), truck_packages(TRUCK_ID,PACKAGE_LOAD)
%         delivery_state(NODE_ID,PACKAGES_LEFT)
%         warehouse_state(NODE_ID,PACKAGES_LEFT)
state(1,truck_at(t1,11 ; t2,12 ; t3,13) ; 1,truck_battery(t1,6 ; t2,7 ; t3,10) ; 1,truck_packages(t1,0 ; t2,0 ; t3,0) ;
      1,delivery_state(3,2) ; 1,delivery_state(6,2) ;
      1,warehouse_state(10,5)
     ).

%*
SUBSEQUENT STATES OF THE WORLD:
- Encode the subsequent states, based on the actions taken

Explanation (max 100 words):
[WRITE YOUR EXPLANATION HERE]
*%

% Consider all possible truck states as fluent
fluent(truck_at(TID,NID)) :- truck(TID,_,_), node(NID).
fluent(truck_battery(TID,0..BC)) :- truck(TID,BC,_).
fluent(truck_packages(TID,0..PC)) :- truck(TID,_,PC).

% Consider all possible delivery states as fluent
fluent(delivery_state(NID,0..MPL)) :- state(1,delivery_state(NID,MPL)).

% Consider all possible warehouse states as fluent
fluent(warehouse_state(NID,0..MPL)) :- state(1,warehouse_state(NID,MPL)).

% Enforce the frame axiom:
% 1. Fluent states stay true unless explicitly made false
state(T,S) :- time(T), fluent(S), state(T-1,S), not make_false(T,S).
% 2. Fluent states that are explicitly made true, become true
state(T,S) :- time(T), fluent(S), make_true(T,S).

% Wait - no need to handle this manually, the frame axiom does for us

% Move to a node; battery level goes down by one
make_true(T+1,truck_at(TID,NIDN))     :- time(T+1),
                                          do(T,TID,move(NIDN)).
make_false(T+1,truck_at(TID,NID))      :- time(T+1),
                                          do(T,TID,move(_)),
                                          state(T,truck_at(TID,NID)).
make_true(T+1,truck_battery(TID,BL-1)) :- time(T+1),
                                          do(T,TID,move(_)),
                                          state(T,truck_battery(TID,BL)).
make_false(T+1,truck_battery(TID,BL)) :-  time(T+1),
                                          do(T,TID,move(_)),
                                          state(T,truck_battery(TID,BL)).

% Load a package; package load goes up by one for the truck
%                 packages left goes down by one for the warehouse
make_true(T+1,truck_packages(TID,PL+1))  :- time(T+1),
                                            do(T,TID,load),
                                            state(T,truck_packages(TID,PL)).
make_false(T+1,truck_packages(TID,PL))   :- time(T+1),
                                            do(T,TID,load),
                                            state(T,truck_packages(TID,PL)).
make_true(T+1,warehouse_state(NID,PL-1)) :- time(T+1),
                                            do(T,TID,load),
                                            state(T,truck_at(TID,NID)),
                                            state(T,warehouse_state(NID,PL)).
make_false(T+1,warehouse_state(NID,PL))  :- time(T+1),
                                            do(T,TID,load),
                                            state(T,truck_at(TID,NID)),
                                            state(T,warehouse_state(NID,PL)).

% Unload a package; package load goes down by one for the truck
%                   packages left goes down by one for the delivery point
make_true(T+1,truck_packages(TID,PL-1)) :- time(T+1),
                                           do(T,TID,unload),
                                           state(T,truck_packages(TID,PL)).
make_false(T+1,truck_packages(TID,PL))  :- time(T+1),
                                           do(T,TID,unload),
                                           state(T,truck_packages(TID,PL)).
make_true(T+1,delivery_state(NID,PL-1)) :- time(T+1),
                                           do(T,TID,unload),
                                           state(T,truck_at(TID,NID)),
                                           state(T,delivery_state(NID,PL)).
make_false(T+1,delivery_state(NID,PL))  :- time(T+1),
                                           do(T,TID,unload),
                                           state(T,truck_at(TID,NID)),
                                           state(T,delivery_state(NID,PL)).

% Charge; battery level goes up by one
make_true(T+1,truck_battery(TID,BL+1)) :- time(T+1),
                                          do(T,TID,charge),
                                          state(T,truck_battery(TID,BL)).
make_false(T+1,truck_battery(TID,BL))  :- time(T+1),
                                          do(T,TID,charge),
                                          state(T,truck_battery(TID,BL)).

%*
RESTRICTIONS ON THE ACTIONS:
- Restrict the actions taken by the trucks, based on the state of the world

Explanation (max 100 words):
[WRITE YOUR EXPLANATION HERE]
*%

% Cannot move to non-adjacent node
:- do(T,TID,move(NIDN)),
   state(T,truck_at(TID,NID)),
   not edge(NID,NIDN).

% Cannot load when not at a warehouse
:- do(T,TID,load),
   state(T,truck_at(TID,NID)),
   not warehouse(NID).

% Cannot load from an empty warehouse
:- do(T,TID,load),
   state(T,truck_at(TID,NID)),
   state(T,warehouse_state(NID,0)).

% Cannot load on full capacity
:- do(T,TID,load),
   truck(TID,_,PC),
   state(T,truck_packages(TID,PC)).

% Cannot unload when not at a delivery point
:- do(T,TID,unload),
   state(T,truck_at(TID,NID)),
   not delivery_point(NID).

% Cannot unload to a full delivery point
:- do(T,TID,unload),
   state(T,truck_at(TID,NID)),
   state(T,delivery_state(NID,0)).

% Cannot unload when not carrying a package
:- do(T,TID,unload),
   state(T,truck_packages(TID,0)).

% Cannot charge when not at a charging station
:- do(T,TID,charge),
   state(T,truck_at(TID,NID)),
   not charging_station(NID).

% Cannot charge on full battery
:- do(T,TID,charge),
   truck(TID,BC,_),
   state(T,truck_battery(TID,BC)).

% Cannot move on empty battery
:- do(T,TID,move(_)),
   state(T,truck_battery(TID,0)).

% Cannot have two trucks at the same position
:- state(T,truck_at(TID1,NID)),
   state(T,truck_at(TID2,NID)),
   TID1 != TID2.

% Cannot swap the positions of two trucks
:- do(T,TID1,move(NID2)),
   do(T,TID2,move(NID1)),
   state(T,truck_at(TID1,NID1)),
   state(T,truck_at(TID2,NID2)),
   TID1 != TID2.

% Symmetry breaking; do not move back and forth
:- do(T,TID,move(_)),
   do(T+1,TID,move(NID1)),
   state(T,truck_at(TID,NID1)).

% Do not run low on battery when not close to a charging station
:- state(T,truck_at(TID,NID)),
   state(T,truck_battery(TID,BL)),
   dist_charging(NID,DC),
   BL < DC.

% Do not leave a delivery point if there are more packages to unload
:- do(T,TID,A),
   state(T,truck_at(TID,NID)),
   state(T,truck_packages(TID,TPL)),
   state(T,delivery_state(NID,DPL)),
   TPL > 0,
   DPL > 0,
   A != unload.

%*
GOAL CONDITIONS:
- Constraints that express that the goal must be reached

Explanation (max 100 words):
[WRITE YOUR EXPLANATION HERE]
*%

% Auxiliary predicates expressing that a goal condition has been met
deliveries_performed(T,NID) :- state(T,delivery_state(NID,0)).
truck_parked(T,TID) :- state(T,truck_at(TID,NID)), parking(NID).
truck_empty(T,TID) :- state(T,truck_packages(TID,0)).
reach_charging(T,TID) :- state(T,truck_at(TID,NID)),
                         state(T,truck_battery(TID,BL)),
                         dist_charging(NID,D),
                         D <= BL.

% Define when the goal is reached
goal(T) :- time(T),
           % all deliveries have been performed
           deliveries_performed(T,NID) : delivery_point(NID) ;
           % all trucks are on a parking spot
           truck_parked(T,TID) : truck(TID,_,_) ;
           % all trucks carry no packages
           truck_empty(T,TID) : truck(TID,_,_) ;
           % all trucks can reach a charging station
           reach_charging(T,TID) : truck(TID,_,_).

% Require that the goal is met at the last time step
:- max_time(T), not goal(T).

% Once the goal is met, stop the clock
:- time(T), max_time(MT), goal(T), T < MT.

%*
OPTIMIZATION:
- Express an optimization statement to find a solution within the smallest
  number of time steps

Explanation (max 100 words):
[WRITE YOUR EXPLANATION HERE]
*%

#minimize { 1,T : time(T) }.
#show do/3.

%*
OPTIONAL: ADDITIONAL RULES
- If you add anything to your program that doesn't fit in any of the other
  headings, put it here.

Explanation (max 100 words):
[WRITE YOUR EXPLANATION HERE]
*%

% Enumerate all possible distances; worst case is when there are no circles in the graph
possible_distance(0..MNID) :- MNID = #max { NID : node(NID) }.

% Calculate the distance between two nodes
distance(NID,NID,0)     :- node(NID). % distance to self is zero
distance(NID1,NID3,D+1) :- possible_distance(D+1),
                           % the two nodes are connected through a third node
                           distance(NID1,NID2,D), edge(NID2,NID3),
                           % make sure there is no smaller path between the nodes
                           not distance(NID1,NID3,SD) : possible_distance(SD), SD <= D.

% Calculate the minimum distance from a node to a charging station
dist_charging(NID,MD) :- node(NID),
                         MD = #min { D,NIDC : distance(NID,NIDC,D), charging_station(NIDC) }.

%*
PRETTY PRINTING
*%
#script (python)

from collections import defaultdict
import clingo

def nesteddict():
   return defaultdict(nesteddict)

def on_model(model):
    goal = None
    actions = defaultdict(dict)
    truck_states = nesteddict()
    delivery_states = defaultdict(dict)
    warehouse_states = defaultdict(dict)

    for atom in model.symbols(atoms=True):
        if atom.name == "goal":
            n = atom.arguments[0].number
            if goal is None:
                goal = n
            else:
                goal = min(goal,n)
        elif atom.name == "max_time":
            max_time = atom.arguments[0].number
        elif atom.name == "do":
            time = atom.arguments[0].number
            truck = str(atom.arguments[1])
            action = str(atom.arguments[2])
            actions[truck][time] = action
        elif atom.name == "state":
            time = atom.arguments[0].number
            state = atom.arguments[1]
            if state.name == "truck_at":
                truck_id = str(state.arguments[0])
                node_id = state.arguments[1].number
                truck_states[truck_id][time]["node"] = node_id
            elif state.name == "truck_battery":
                truck_id = str(state.arguments[0])
                battery = state.arguments[1].number
                truck_states[truck_id][time]["battery"] = battery
            elif state.name == "truck_packages":
                truck_id = str(state.arguments[0])
                packages = state.arguments[1].number
                truck_states[truck_id][time]["packages"] = packages
            elif state.name == "delivery_state":
                node_id = state.arguments[0].number
                packages = state.arguments[1].number
                delivery_states[node_id][time] = packages
            elif state.name == "warehouse_state":
                node_id = state.arguments[0].number
                packages = state.arguments[1].number
                warehouse_states[node_id][time] = packages

    print("\n********* Truck Actions **********")
    for truck_id, truck_actions in actions.items():
        time_steps = sorted([time for time in truck_actions.keys()])
        print(f"Truck {truck_id}:")
        for time in time_steps:
            print(f"- [t={time}]: {truck_actions[time]}")
    print("**********************************\n")

    print("********** Final States **********")
    print(f"- Goal reached at t={goal}")
    for truck_id, truck_state in truck_states.items():
        node = truck_state[max_time]["node"]
        battery = truck_state[max_time]["battery"]
        packages = truck_state[max_time]["packages"]
        print(f"- Truck {truck_id} @{node} P {packages} B {battery}")
    for node_id, delivery_state in delivery_states.items():
        packages = delivery_state[max_time]
        print(f"- Delivery @{node_id}, packages left: {packages}")
    for node_id, warehouse_state in warehouse_states.items():
        packages = warehouse_state[max_time]
        print(f"- Warehouse @{node_id}, packages left: {packages}")
    print("**********************************\n")

def main(prg):
    prg.ground([("base", [])])
    prg.solve(on_model=on_model)

#end.

%*
THE END
*%
