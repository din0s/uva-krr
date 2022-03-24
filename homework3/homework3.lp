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

% Represent the charging stations, delivery points, warehouses and parking spots
% using unary predicates based on the node they are on.
charging_station(1;2).
delivery_point(3;6).
warehouse(10).
parking(11..13).

% Represent the trucks using truck/3. The 3 arguments represent the id,
% battery capacity and package capacity of each truck.
truck(t1,10,1 ; t2,10,2 ; t3,10,3).

%*
TIME STEPS:
- Represent the different time steps (up to some upper bound)
*%

#const t=25. % This is an upper bound on the number of time steps needed.

% Generate all possible time steps.
valid_time(1..t).

% Choose a sequence of time steps.
{ time(T) : valid_time(T) }.

% Start at time 1
:- not time(1).

% Ensure that time steps are consecutive.
:- valid_time(T), valid_time(T+1), time(T+1), not time(T).

% Define max time as the last time step.
max_time(MT) :- MT = #max { T : time(T) }.

%*
ACTIONS:
- Represent the possible actions that each truck can take
*%

% Define all possible actions.
% Wait, load, unload and charge are well-defined actions given a truck state,
% and hence are represented as predicates with zero arity. On the contrary, move 
% also requires a destination node, so it's represented with a unary predicate.
action(wait;load;unload;charge).
action(move(NID)) :- node(NID).

%*
GENERATE A SEQUENCE OF ACTIONS:
- Generate a sequence of actions (for each truck)
*%

% Define the predicate do/3, describing that an action is performed by a truck 
% at a certain time stepm, and enfore the modelling choice that each truck can 
% perform exactly one action per time step (except for the final one).
1 { do(T,TID,A) : action(A) } 1 :- time(T), truck(TID,_,_), max_time(MT), T < MT.

%*
INITIAL STATE:
- Encode the initial state
*%

%*
Define the predicate state/2, describing an entity's state at a given time.
More specifically, we have the following entity states:
  * truck_at/2        (denoting the position of a truck)
  * truck_battery/2   (denoting the battery level of a truck)
  * truck_packages/2  (denoting the package load of a truck)
  * delivery_state/2  (denoting the number of remaining packages required by a delivery point)
  * warehouse_state/2 (denoting the number of remaining packages present at a warehouse)

Subsequently, we encode the initial state of the problem, using the aforementioned predicates.
*%
state(1,truck_at(t1,11 ; t2,12 ; t3,13) ; 1,truck_battery(t1,6 ; t2,7 ; t3,10) ; 1,truck_packages(t1,0 ; t2,0 ; t3,0) ;
      1,delivery_state(3,2) ; 1,delivery_state(6,2) ;
      1,warehouse_state(10,5)
     ).

%*
SUBSEQUENT STATES OF THE WORLD:
- Encode the subsequent states, based on the actions taken

Explanation (max 100 words):
First, we declare all entity states as fluent and enforce the frame axiom.
Then, for each of the possible actions, we explicitly set the state for the
involved entities to reflect the updated world in the next time step. Thanks
to the frame axiom, non-involved entities will have their states preserved,
without requiring aditional rules.
*%

% Consider all possible entity states as fluent.
fluent(truck_at(TID,NID)) :- truck(TID,_,_), node(NID).
fluent(truck_battery(TID,0..BC)) :- truck(TID,BC,_).
fluent(truck_packages(TID,0..PC)) :- truck(TID,_,PC).
fluent(delivery_state(NID,0..MPL)) :- state(1,delivery_state(NID,MPL)).
fluent(warehouse_state(NID,0..MPL)) :- state(1,warehouse_state(NID,MPL)).

% Enforce the frame axiom:
% 1. Fluent states stay true unless explicitly made false
state(T,S) :- time(T), fluent(S), state(T-1,S), not make_false(T,S).
% 2. Fluent states that are explicitly made true, become true
state(T,S) :- time(T), fluent(S), make_true(T,S).

% Wait: no need to handle this manually, since the entity's state does not change.

% Move to a node: update truck's position and decrease battery level by one.
make_true(T+1,truck_at(TID,NIDN))      :- time(T+1),
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

% Load a package: increase the truck's load by one and decrease the available
%                 packages at the warehouse by one.
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

% Unload a package: decrease the truck's load by one and decrease the remaiming
%                   packages required by the delivery point by one.
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

% Charge: increase the truck's battery level by one.
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
The program explores all actions at any given time step, but this can violate
the conditions required to actually perform some of these actions. To this end,
we introduce 12 constraints, which ensure the validity of the explored actions.
Additionally, we add an optimization constraint to efficiently limit the search 
space by foreseeing and discarding actions that lead to dead-end states (after 
which the problem cannot be solved).
*%

% 1. Cannot move to non-adjacent node
:- do(T,TID,move(NIDN)),
   state(T,truck_at(TID,NID)),
   not edge(NID,NIDN).

% 2. Cannot load when not at a warehouse
:- do(T,TID,load),
   state(T,truck_at(TID,NID)),
   not warehouse(NID).

% 3. Cannot load from an empty warehouse
:- do(T,TID,load),
   state(T,truck_at(TID,NID)),
   state(T,warehouse_state(NID,0)).

% 4. Cannot load on full capacity
:- do(T,TID,load),
   truck(TID,_,PC),
   state(T,truck_packages(TID,PC)).

% 5. Cannot unload when not at a delivery point
:- do(T,TID,unload),
   state(T,truck_at(TID,NID)),
   not delivery_point(NID).

% 6. Cannot unload to a full delivery point
:- do(T,TID,unload),
   state(T,truck_at(TID,NID)),
   state(T,delivery_state(NID,0)).

% 7. Cannot unload when not carrying a package
:- do(T,TID,unload),
   state(T,truck_packages(TID,0)).

% 8. Cannot charge when not at a charging station
:- do(T,TID,charge),
   state(T,truck_at(TID,NID)),
   not charging_station(NID).

% 9. Cannot charge on full battery
:- do(T,TID,charge),
   truck(TID,BC,_),
   state(T,truck_battery(TID,BC)).

% 10. Cannot move on empty battery
:- do(T,TID,move(_)),
   state(T,truck_battery(TID,0)).

% 11. Cannot have two trucks at the same position (due to node capacity being 1)
:- state(T,truck_at(TID1,NID)),
   state(T,truck_at(TID2,NID)),
   TID1 != TID2.

% 12. Cannot swap the positions of two trucks (due to edge capacity being 1)
:- do(T,TID1,move(NID2)),
   do(T,TID2,move(NID1)),
   state(T,truck_at(TID1,NID1)),
   state(T,truck_at(TID2,NID2)),
   TID1 != TID2.

% Optimization: do not run low on battery when not close to a charging station
:- state(T,truck_at(TID,NID)),
   state(T,truck_battery(TID,BL)),
   dist_charging(NID,DC),
   BL < DC.

%*
GOAL CONDITIONS:
- Constraints that express that the goal must be reached

Explanation (max 100 words):
First, we define 4 predicates that correspond to the 4 properities needed to 
achive the goal, as defined by the assignment. Then, we check whether there 
exists a time step where all conditions are met for every truck and delivery
point. We specify that it cannot be the case that the goal is not met at the 
final time step, and we also stop the clock when the goal is met.
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
Our aim is to find a solution in the least amount of time steps. To this end,
we minimize the number of time steps using the #minimize optimization statement.
For each time step present in the answer set, this optimization statement adds
one to the tally and provides an answer set corresponding to the smallest sum.
*%

#minimize { 1,T : time(T) }.
#show do/3.

%*
OPTIONAL: ADDITIONAL RULES
- If you add anything to your program that doesn't fit in any of the other
  headings, put it here.

Explanation (max 100 words):
In this section, we aim to calculate the distance of each node to its closest
charging station. We start by constructing a predicate denoting all plaussible 
distances in a graph with N nodes, i.e. {0, 1, ..., N}. This serves as an upper
limit in order to define the recursive predicate distance/3, which encodes the 
minimum distance between each pair of nodes in the problem's map. Finally, we
utilize distance/3 to find the required quantity, encoded in the predicate
dist_charging/2.
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
