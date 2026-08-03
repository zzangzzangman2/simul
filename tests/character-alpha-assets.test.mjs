import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repoRoot = fileURLToPath(new URL("..", import.meta.url));
const imageRoot = path.join(repoRoot, "flutter_app", "assets", "images");
const publicImageRoot = path.join(
  repoRoot,
  "public",
  "play",
  "assets",
  "assets",
  "images",
);

const spriteDirectories = [
  "production_soft_painted/kim_seoa",
  "production_soft_painted/lee_jian",
  "production_soft_painted/choi_iseo",
  "production_soft_painted/jung_arin",
  "production_soft_painted/park_haeun",
  "production_soft_painted/han_sua",
  "production_soft_painted/oh_jiwoo",
  "production_soft_painted/yoon_chaea",
  "cinematic_soft_painted/decimal_nis_1999/characters",
];

async function approvedSpritePaths() {
  const paths = [];
  for (const directory of spriteDirectories) {
    const files = (await readdir(path.join(imageRoot, directory)))
      .filter((file) => file.endsWith(".png"))
      .sort();
    paths.push(...files.map((file) => `${directory}/${file}`));
  }
  return paths;
}

test("approved v3 sprites remain byte-exact and mirrored to the web build", async () => {
  const sprites = await approvedSpritePaths();
  assert.equal(sprites.length, 78);

  const digest = createHash("sha256");
  for (const relative of sprites) {
    const source = await readFile(path.join(imageRoot, relative));
    const publicCopy = await readFile(path.join(publicImageRoot, relative));
    assert.deepEqual(publicCopy, source, relative);
    digest.update(relative);
    digest.update("\0");
    digest.update(source);
  }

  const styleAnchor = await readFile(
    path.join(
      repoRoot,
      "art_references",
      "simul_polished_soft_render_vn_style_anchor_v3.png",
    ),
  );
  digest.update("art_references/simul_polished_soft_render_vn_style_anchor_v3.png");
  digest.update("\0");
  digest.update(styleAnchor);

  assert.equal(
    digest.digest("hex"),
    "c4b2fce25787e553e27917f66804ead554825c3ec31114f315a40cc54f554591",
  );
});
