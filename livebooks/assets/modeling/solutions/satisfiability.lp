atom(A) :- literal(C,V,A).
{ holds(pos,A) } :- atom(A).
{ holds(neg,A) } :- atom(A).
:- atom(A), { holds(pos,A); holds(neg,A) } != 1.
satisfied(C) :- literal(C,V,A), holds(V,A).
:- clause(C), not satisfied(C).
#show holds/2.
