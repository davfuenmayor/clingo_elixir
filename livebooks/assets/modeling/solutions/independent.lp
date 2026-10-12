{ select(Item) } :- vertex(Item).
:- edge(Item,Other), select(Item), select(Other).
:- threshold(N), { select(Item) } N-1.
#show select/1.
