letter(s;e;n;d;m;o;r;y).
&sum {Item} >= 0 :- letter(Item).
&sum {Item} <= 9 :- letter(Item).
&sum {              1000*s ;  100*e ;  10*n ;  1*d
     ;              1000*m ;  100*o ;  10*r ;  1*e
     ;  -10000*m ; -1000*o ; -100*n ; -10*e ; -1*y } = 0.
&sum { m } > 0.
{ less(Item,Other); less(Other,Item) } = 1 :- letter(Item), letter(Other), Item < Other.
&sum { Item } < Other :- less(Item,Other).
#show.
