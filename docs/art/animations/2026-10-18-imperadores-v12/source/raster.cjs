const fs=require('fs');
function inside(x,y,p){let hit=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const a=p[i],b=p[j];if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])hit=!hit;}return hit;}
const blank=s=>new Uint32Array(s*s);
function color(h){return (parseInt(h.slice(1),16)*256+255)>>>0;}
function unpack(v){return [v>>>24,(v>>>16)&255,(v>>>8)&255,v&255];}
function rgba(p){const b=Buffer.alloc(p.length*4);for(let i=0;i<p.length;i++)if(p[i])b.set(unpack(p[i]),i*4);return b;}
function base(c){const p=blank(c.width);for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++)if(c.rows[y][x]!=='.')p[y*c.width+x]=color(c.palette[c.rows[y][x]]);for(const e of c.nativeEdits)p[e.y*c.width+e.x]=e.color?color(e.color):0;return p;}
function split(p,s,rig){const layers={body:Uint32Array.from(p)};for(const [name,poly]of Object.entries(rig.parts)){layers[name]=blank(s);for(let y=0;y<s;y++)for(let x=0;x<s;x++)if(inside(x+.5,y+.5,poly)){const n=y*s+x;for(const a of Object.values(layers))if(a[n]){layers[name][n]=a[n];if(a!==layers[name])a[n]=0;}}}return layers;}
function bounds(p,s){let x0=s,y0=s,x1=-1,y1=-1;for(let y=0;y<s;y++)for(let x=0;x<s;x++)if(p[y*s+x]){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}return [x0,y0,x1,y1];}
function merge(layers,s){const out=blank(s);for(const a of layers)for(let i=0;i<out.length;i++)if(a[i])out[i]=a[i];return out;}
function transform(p,s,o={}){const out=blank(s),[px,py]=o.pivot||[s/2,s/2],a=(o.angle||0)*Math.PI/180,co=Math.cos(a),si=Math.sin(a);let dx=o.dx||0,dy=o.dy||0,x0=s,y0=s,x1=-1,y1=-1;for(let y=0;y<s;y++)for(let x=0;x<s;x++)if(p[y*s+x]){const u=Math.round(px+(x-px)*co-(y-py)*si+dx),v=Math.round(py+(x-px)*si+(y-py)*co+dy);x0=Math.min(x0,u);x1=Math.max(x1,u);y0=Math.min(y0,v);y1=Math.max(y1,v);}dx+=Math.max(-x0,Math.min(0,s-1-x1));dy+=Math.max(-y0,Math.min(0,s-1-y1));for(let y=0;y<s;y++)for(let x=0;x<s;x++){const tx=x-dx-px,ty=y-dy-py,sy=Math.round(-si*tx+co*ty+py),sx=Math.round(co*tx+si*ty+px);if(sx>=0&&sy>=0&&sx<s&&sy<s)out[y*s+x]=p[sy*s+sx];}return out;}
function leg(p,s,o){const out=blank(s),h=o.hip,b=o.boot,dx=o.dx||0,dy=o.dy||0,bob=o.bob||0;for(let y=0;y<s;y++)for(let x=0;x<s;x++){let sy=y;for(let k=0;k<4;k++){const t=Math.max(0,Math.min(1,(sy-h)/(b-h)));sy=y-bob*(1-t)-dy*t;}const t=Math.max(0,Math.min(1,(sy-h)/(b-h))),sx=Math.round(x-dx*t);sy=Math.round(sy);if(sx>=0&&sy>=0&&sx<s&&sy<s)out[y*s+x]=p[sy*s+sx];}return out;}
function set(p,s,x,y,v){x=Math.round(x);y=Math.round(y);if(x>=0&&y>=0&&x<s&&y<s)p[y*s+x]=v;}
function line(p,s,x0,y0,x1,y1,v,width=1){const n=Math.max(Math.abs(x1-x0),Math.abs(y1-y0));for(let i=0;i<=n;i++){const t=n?i/n:0;for(let k=0;k<width;k++)set(p,s,x0+(x1-x0)*t+k,y0+(y1-y0)*t,v);}}
function disk(p,s,x,y,r,v){for(let j=-r;j<=r;j++)for(let i=-r;i<=r;i++)if(i*i+j*j<=r*r)set(p,s,x+i,y+j,v);}
function poly(p,s,points,v){for(let y=0;y<s;y++)for(let x=0;x<s;x++)if(inside(x+.5,y+.5,points))p[y*s+x]=v;}
function mirror(p,s){const q=blank(s);for(let y=0;y<s;y++)for(let x=0;x<s;x++)q[y*s+x]=p[y*s+s-1-x];return q;}
function paintClosed(p,s,c,rig){const skin=color(c.palette[rig.skin]),lid=color(c.palette[rig.lid]);for(const [x,y,w,h]of rig.eyes){for(let j=0;j<h;j++)for(let i=0;i<w;i++)if(p[(y+j)*s+x+i])set(p,s,x+i,y+j,j===Math.floor(h/2)?lid:skin);}return p;}
module.exports={blank,color,unpack,rgba,base,split,bounds,merge,transform,leg,set,line,disk,poly,mirror,paintClosed,inside};
