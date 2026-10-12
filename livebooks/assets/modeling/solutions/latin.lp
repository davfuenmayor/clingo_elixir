number(1..S) :- size(S).
{ latin(Item,Other,N) } :- number(Item), number(Other), number(N).
:- number(Item), number(Other), { latin(Item,Other,N) : number(N) } != 1.
:- number(Item), number(N), { latin(Item,Other,N) : number(Other) } != 1.
:- number(Other), number(N), { latin(Item,Other,N) : number(Item) } != 1.
#show latin/3.
