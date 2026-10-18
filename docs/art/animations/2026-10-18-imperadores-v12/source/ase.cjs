const zlib=require('zlib');
function chunk(type,data){const h=Buffer.alloc(6);h.writeUInt32LE(data.length+6);h.writeUInt16LE(type,4);return Buffer.concat([h,data]);}
function str(v){const b=Buffer.from(v,'utf8'),h=Buffer.alloc(2);h.writeUInt16LE(b.length);return Buffer.concat([h,b]);}
module.exports=(width,height,names,frames,tags,pivot)=>{
 const colours=new Map([['00000000',Buffer.alloc(4)]]);
 for(const f of frames)for(const b of Object.values(f.layers))for(let i=0;i<b.length;i+=4)if(b[i+3])colours.set(b.subarray(i,i+4).toString('hex'),b.subarray(i,i+4));
 const all=[];
 for(const [fi,f]of frames.entries()){
  const chunks=[];
  if(fi===0){
   const ph=Buffer.alloc(20);ph.writeUInt32LE(colours.size);ph.writeUInt32LE(colours.size-1,8);
   chunks.push(chunk(0x2019,Buffer.concat([ph,...[...colours.values()].map(c=>Buffer.concat([Buffer.alloc(2),c]))])));
   for(const name of names){const l=Buffer.alloc(16);l.writeUInt16LE(3);l[12]=255;chunks.push(chunk(0x2004,Buffer.concat([l,str(name)])));}
   const th=Buffer.alloc(10);th.writeUInt16LE(tags.length);
   const ts=tags.map(t=>{const b=Buffer.alloc(17);b.writeUInt16LE(t.from);b.writeUInt16LE(t.to,2);b.writeUInt16LE(t.loop?0:1,5);b[13]=108;b[14]=174;b[15]=164;return Buffer.concat([b,str(t.name)]);});
   chunks.push(chunk(0x2018,Buffer.concat([th,...ts])));
   const sh=Buffer.alloc(12);sh.writeUInt32LE(1);sh.writeUInt32LE(2,4);const key=Buffer.alloc(28);key.writeUInt32LE(width,12);key.writeUInt32LE(height,16);key.writeInt32LE(pivot[0],20);key.writeInt32LE(pivot[1],24);
   chunks.push(chunk(0x2022,Buffer.concat([sh,str('ground_pivot'),key])));
  }
  for(const [li,name]of names.entries()){
   const b=f.layers[name];if(!b||!b.some((v,i)=>i%4===3&&v))continue;
   const ch=Buffer.alloc(20);ch.writeUInt16LE(li);ch[6]=255;ch.writeUInt16LE(2,7);ch.writeUInt16LE(width,16);ch.writeUInt16LE(height,18);
   chunks.push(chunk(0x2005,Buffer.concat([ch,zlib.deflateSync(b,{level:9})])));
  }
  const b=Buffer.concat(chunks),h=Buffer.alloc(16);h.writeUInt32LE(b.length+16);h.writeUInt16LE(0xF1FA,4);h.writeUInt16LE(chunks.length,6);h.writeUInt16LE(f.ms,8);h.writeUInt32LE(chunks.length,12);all.push(h,b);
 }
 const payload=Buffer.concat(all),h=Buffer.alloc(128);h.writeUInt32LE(128+payload.length);h.writeUInt16LE(0xA5E0,4);h.writeUInt16LE(frames.length,6);h.writeUInt16LE(width,8);h.writeUInt16LE(height,10);h.writeUInt16LE(32,12);h.writeUInt32LE(1,14);h.writeUInt16LE(100,18);h.writeUInt16LE(Math.min(65535,colours.size),32);h[34]=h[35]=1;h.writeUInt16LE(1,40);h.writeUInt16LE(1,42);
 return Buffer.concat([h,payload]);
};
