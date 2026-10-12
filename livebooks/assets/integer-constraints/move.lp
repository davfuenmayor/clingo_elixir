#const end=3.
#const stepsize=10.
step(0..end).
&sum { at(T) } >= 0          :- step(T).
&sum { at(T) } <= T*stepsize :- step(T).
&sum {at(0)} = 0.
{move(T)} :- step(T); T > 0.
&sum {at(T-1); stepsize; -at(T)} = 0 :- move(T).
&sum {at(T-1); -at(T)} = 0 :- not move(T); step(T); step(T-1).
&sum {at(end)} >= 20.
#show move/1.
