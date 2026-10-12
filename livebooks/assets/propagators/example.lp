dom(1..2).
{ a(Item) } :- dom(Item).
{ b(Item) } :- dom(Item).
c(Item) :- b(Item).
:- a(Item), not c(Item).
:- not a(Item), c(Item).
