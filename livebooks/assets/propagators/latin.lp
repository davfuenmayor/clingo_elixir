number(1..3).
latin(1,1,1).
1 { latin(Item,Other,N) : number(N) } 1 :- number(Item), number(Other).
:- latin(Item,Y1,N), latin(Item,Y2,N), Y1 < Y2, number(Item), number(N).
:- latin(X1,Other,N), latin(X2,Other,N), X1 < X2, number(Other), number(N).
#show latin/3.
