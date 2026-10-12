{ value(F,V) : option(T,V) } = 1 :- feature(_,F,T,_,_).
:- behavior((S,C)), require((S,C),B), not holds_binary(B).
holds_binary(B) :- binary(_,B,Left,"=",Right), value(Left,LV), value(Right,RV), LV = RV.
#show value/2.
