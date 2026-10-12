{ select(Item) } :- vertex(Item).
dominated(Item) :- select(Item).
dominated(Other) :- select(Item), edge(Item,Other).
dominated(Other) :- select(Item), edge(Other,Item).
:- vertex(Item), not dominated(Item).
:- threshold(N), N+1 { select(Item) }.
#show select/1.
