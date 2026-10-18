const zlib=require('zlib');
function chunk(type,data){const h=Buffer.alloc(6);h.writeUInt32LE(data.length+6);h.writeUInt16LE(type,4);return Buffer.concat([h,data]);}
function str(value){const b=Buffer.from(value,'utf8'),h=Buffer.alloc(2);h.writeUInt16LE(b.length);return Buffer.concat([h,b]);}
function writeAse(width,height,layers,pivot){
 const chunks=[];
 const colours=new Map([['00000000',Buffer.alloc(4)]]);
 for(const layer of layers)for(let i=0;i<layer.rgba.length;i+=4)if(layer.rgba[i+3]){const c=layer.rgba.subarray(i,i+4);colours.set(c.toString('hex'),c);}
 const ph=Buffer.alloc(20);ph.writeUInt32LE(colours.size);ph.writeUInt32LE(colours.size-1,8);
 chunks.push(chunk(0x2019,Buffer.concat([ph,...[...colours.values()].map(c=>Buffer.concat([Buffer.alloc(2),c]))])));
 for(const [index,layer] of layers.entries()){
  const info=Buffer.alloc(16);info.writeUInt16LE(3,0);info[12]=255;
  chunks.push(chunk(0x2004,Buffer.concat([info,str(layer.name)])));
  if(!layer.rgba.some((v,i)=>i%4===3&&v))continue;
  const cel=Buffer.alloc(20);cel.writeUInt16LE(index);cel[6]=255;cel.writeUInt16LE(2,7);cel.writeUInt16LE(width,16);cel.writeUInt16LE(height,18);
  chunks.push(chunk(0x2005,Buffer.concat([cel,zlib.deflateSync(layer.rgba,{level:9})])));
 }
 const s=Buffer.alloc(12);s.writeUInt32LE(1);s.writeUInt32LE(2,4);
 const key=Buffer.alloc(28);key.writeUInt32LE(width,12);key.writeUInt32LE(height,16);key.writeInt32LE(pivot[0],20);key.writeInt32LE(pivot[1],24);
 chunks.push(chunk(0x2022,Buffer.concat([s,str('ground_pivot'),key])));
 const body=Buffer.concat(chunks),frame=Buffer.alloc(16);
 frame.writeUInt32LE(16+body.length);frame.writeUInt16LE(0xF1FA,4);frame.writeUInt16LE(chunks.length,6);frame.writeUInt16LE(100,8);frame.writeUInt32LE(chunks.length,12);
 const header=Buffer.alloc(128);header.writeUInt32LE(128+16+body.length);header.writeUInt16LE(0xA5E0,4);header.writeUInt16LE(1,6);
 header.writeUInt16LE(width,8);header.writeUInt16LE(height,10);header.writeUInt16LE(32,12);header.writeUInt32LE(1,14);header.writeUInt16LE(100,18);
 header.writeUInt16LE(colours.size,32);header[34]=1;header[35]=1;header.writeUInt16LE(1,40);header.writeUInt16LE(1,42);
 return Buffer.concat([header,frame,body]);
}
module.exports=writeAse;
