{ select(Item) } :- vertex(Item).
covered(Item,Other) :- edge(Item,Other), select(Item).
covered(Item,Other) :- edge(Item,Other), select(Other).
:- edge(Item,Other), not covered(Item,Other).
:- threshold(N), N+1 { select(Item) }.
#show select/1.
