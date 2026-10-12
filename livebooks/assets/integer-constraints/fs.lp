            machine(1).      machine(2).
task(a). duration(a,1,3). duration(a,2,4).
task(b). duration(b,1,1). duration(b,2,6).
task(c). duration(c,1,5). duration(c,2,5).
1 { cycle(T,U) : task(U), U != T } 1 :- task(T).
1 { cycle(T,U) : task(T), U != T } 1 :- task(U).
reach(M) :- M = #min { T : task(T) }.
reach(U) :- reach(T), cycle(T,U).
:- task(T), not reach(T).
1 { start(T) : task(T) } 1.
permutation(T,U) :- cycle(T,U), not start(U).
seq((T,M),(T,M+1),D) :- task(T), duration(T,M,D), machine(M+1).
seq((T1,M),(T2,M),D) :- permutation(T1,T2), duration(T1,M,D).
&sum { T2; -T1 } >= D        :- seq(T1,T2,D).
&sum { (T,M) } >= 0          :- duration(T,M,D).
&sum { (T,M); -bound } <= -D :- duration(T,M,D).
&sum{ bound } = 16.
#show permutation/2.
