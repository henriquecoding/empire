const make=(name,n,loop=false,fps=10,events=[])=>({name,n,loop,fps,events});
const common=[make('idle',6,true),make('walk',8,true),make('run',6,true,12),make('hit',2),make('die',7),make('rise',6),make('interact',4),make('celebrate',6),make('blink',3)];
const extra={
 rei:[make('attack',5,false,10,[{frame:2,name:'melee_hit'}]),make('command',6),make('pay',4,false,10,[{frame:2,name:'coin_release'}])],
 escudeiro:[make('block',3,false,10,[{frame:1,name:'guard_ready'}]),make('block_hold',4,true),make('block_hit',3)],
 nia:[make('attack',5,false,10,[{frame:2,name:'axe_hit'}]),make('command',4)],
 bardo:[make('play',6,true),make('cast',6,false,10,[{frame:3,name:'song_cast'}]),make('inspire',6,true)],
 arqueiro:[make('shoot',5,false,10,[{frame:2,name:'arrow_release',socket:[74,33]}]),make('reload',3),make('mark',4),make('pay',4,false,10,[{frame:2,name:'coin_release'}])],
 intendente:[make('receive',4),make('deliver',6,false,10,[{frame:3,name:'arrows_delivered'}]),make('collect',4),make('no_payment',4)],
 sombra:[make('sit',6),make('heal',8,true),make('stand',6)],
 dancarina:[make('dance_start',4),make('dance',8,true,10,[{frame:3,name:'dance_pulse'}]),make('dance_end',4)]
};
module.exports=id=>[...common.filter(a=>id!=='sombra'||a.name!=='blink'),...extra[id]];
