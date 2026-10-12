  dom(1..2).
  a(Item) :- dom(Item).
b(Item) :- not a(Item), dom(Item).
  { c(Item) } :- dom(Item).
  d(Item) :- not c(Item), dom(Item).
  e(Item); f(Item); g(Item) :- c(Item), d(Item), dom(Item).
  { e(Item); f(Item); g(Item) } :- c(Item), d(Item), dom(Item).
h :- d(1), 1 { e(Item); f(Item) }.
i :- d(1), 1 { e(Item); f(Item) } 1.
:- h, i.
#show (e(Item),f(Item),g(Item)) : e(Item), f(Item), g(Item).
  #minimize{ 1@3,Item : e(Item); 2@3,Item : f(Item); 3,Item : g(Item)}.
  #external j. [true]
  #heuristic e(Item) : c(Item). [1,level]
  #project e/1.
