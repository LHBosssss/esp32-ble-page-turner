import { createOpenSCAD } from "openscad-wasm-prebuilt";
import fs from "fs";
const [,, src, outDir, ...parts] = process.argv;
const code = fs.readFileSync(src, "utf8");
fs.mkdirSync(outDir, { recursive: true });
for (const p of parts) {
  const o = await createOpenSCAD({ print: ()=>{}, printErr: (m)=>console.error("[scad]", m) });
  const c = code.replace(/^part\s*=\s*"[^"]*";/m, `part = "${p}";`);
  try {
    const stl = await o.renderToStl(c);
    fs.writeFileSync(`${outDir}/${p}.stl`, stl);
    console.log(p, "OK", stl.length, "bytes");
  } catch (e) { console.log(p, "FAIL", e.message); }
}
