# Lee Jian expression set v2 — final prompt set

Generation mode: built-in `imagegen`, one image per pose. Chroma source was generated on
flat `#00FF00`, then converted locally to validated RGBA transparency.

## Shared reference roles

- Image 1: `simul_production_soft_painted_vn_style_anchor_v1.png` — rendering grammar and common uniform only; never copy Sua's face, hair, or body.
- Image 2: `lee_jian_face_identity_anchor_v2.png` — absolute face identity.
- Image 3: approved pose 01 full-body source / `lee_jian_identity_anchor_v2.png` — absolute body, outfit, scale, hair length, and baseline.
- Pose 02 also used the user's approved wink reference as expression-only guidance.

## Shared invariant prompt

Create one production-ready full-body SIMUL visual-novel sprite in `SIMUL production soft-painted VN anime v1`. Preserve the exact same Lee Jian: compact rounded face, full soft cheeks, extremely short blunt-rounded chin, large gentle nearly round honey-gold eyes, tiny nose, tiny near-straight mouth, broad restrained blush, warm milk-tea beige-blonde long hair, dense rounded U-shaped bangs, wide white cloth headband, and visible rear white bow with ribbon tails. Preserve medium relative height, gently sloped narrow-to-medium shoulders, medium torso, natural moderate pelvis, slightly long slim limbs, healthy softly shaped legs, and relaxed one-leg weight habit. Preserve the common uniform: normal-length opaque white short-sleeved button-up shirt fully covering abdomen and navel, red/black/white tartan tie, matching pleated skirt with overlapping V-shaped high waist panel, and decorated coral-pink ventilated clogs on bare feet and ankles with no socks. One complete character from topmost hair and ribbon to complete shoe soles, both hands and all props visible, 1024×1536 portrait slot, generous padding, flat pure `#00FF00` background, no shadow, floor, scenery, text, logo, or watermark. Avoid face drift, longer or V-shaped chin, narrow cheeks, lifted cat eyes, dark hair or irises, missing headband/bow, changed body, crop shirt, exposed abdomen, socks, malformed hands, cropped extremities, rigid mannequin poses, chibi, photorealism, 3D, and heavy black outlines.

## Pose deltas

1. `01_neutral_screwdriver_v2.png`: quiet neutral micro-smile, both eyes open, head tilted about 3 degrees, subtly counter-angled shoulders, one relaxed knee, red-handled screwdriver hanging safely from the right hand, left hand relaxed, direct listening gaze, gentle lateral hair and ribbon drift.
2. `02_playful_wink_v2.png`: close only the left eye into a soft curved wink, keep the right honey-gold eye open, tiny restrained closed-mouth smile, warmer blush, head tilted toward the closed eye, upper body leaning slightly forward, left hand beside cheek with relaxed fingers, screwdriver near right hip, front foot half a step forward, hair and ribbon drifting opposite the tilt.
3. `03_focused_repair_v2.png`: torso turned about 25 degrees and bent slightly forward, head lowered toward the hands, eyes focused on the screwdriver tip, brows gently drawn inward, tiny neutral mouth, screwdriver in right hand and tiny screw between left thumb and forefinger, one foot forward, hair falling over one shoulder.
4. `04_surprised_fault_v2.png`: small mechanical click surprise, eyes wider, brows lifted, restrained small round mouth, head snapping up and turning about 12 degrees, torso recoiling slightly, shoulders unevenly raised, screwdriver safely raised sideways/down, left hand open at chest height, rear-foot weight, hair and ribbon delayed rebound.
5. `05_worried_diagnosis_v2.png`: head down and slightly right, diagonal gaze toward tool, inner brows raised and knit, tiny closed mouth with slight downward corners, shoulders lowered, screwdriver horizontal between two clearly visible hands, elbows close, centered-back weight, hair and ribbons settled downward.
6. `06_annoyed_interrupted_v2.png`: restrained concentration interruption, head and gaze turned about 20 degrees left while torso stays partly forward, slightly lowered brows with one subtly higher, tiny closed pout, left hand on waist, screwdriver safely upright beside right shoulder, strong one-leg weight and opposite knee bent, hair and ribbons trailing opposite the turn.
7. `07_apologetic_boundary_v2.png`: torso turned about 15 degrees, head gently bowed, eyes looking upward under worried brows, tiny straight apologetic mouth and extra blush, left hand over upper chest, screwdriver lowered beside thigh, shoulders modestly inward, close feet and one bent knee, hair falling forward and ribbon hanging still.
8. `08_determined_repair_v2.png`: focused direct gaze, slightly lowered brows, tiny firm smile, torso turned about 15 degrees and leaning forward, screwdriver in safe working grip at chest height, small relaxed left fist near waist, staggered stance with front foot and lifted rear heel, hair and ribbons drifting backward.
9. `09_explaining_mechanism_v2.png`: relaxed three-quarter head and torso, attentive eye contact, one brow subtly lifted, small calm speaking mouth, screwdriver held horizontally as a pointer toward empty side space, left palm open at mid-chest, counter-angled shoulders and one relaxed knee, gentle sideways hair and ribbon sway.
