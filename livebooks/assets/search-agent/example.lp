dom(1..2).
{ a(Item) } :- dom(Item).
{ b(Item) } :- dom(Item).
:- a(Item), not b(Item).
:- not a(Item), b(Item).
