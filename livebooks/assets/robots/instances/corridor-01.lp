#const n=11.
edge(Item,Item+1) :- Item=1..4.
edge(3,4+2).
robot(r1,c1,1).
robot(r2,c2,5).
job(j1,c1,11).
  operation(j1,1,1).
  operation(j1,2,5).
  operation(j1,3,1).
job(j2,c2,10).
  operation(j2,1,5).
  operation(j2,2,1).
  operation(j2,3,5).
