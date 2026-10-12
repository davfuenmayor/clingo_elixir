{ select(Item) } :- element(S,Item).
:- set(S), { select(Item) : element(S,Item) } != 1.
#show select/1.
