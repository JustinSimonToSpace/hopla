# Contributing to Hopla

Thanks for helping Hopla get more people moving! 🌱

Hopla is source available under the PolyForm Noncommercial license. Before your first pull request is merged,
a bot asks you to sign the [Contributor License Agreement](CLA.md) with a single comment: you keep the
copyright of your work, and the project can keep evolving, including under other terms in the future.

## Development

```sh
swift build
swift run Hopla --now --fast                      # see Hopla right away, with short exercises
./scripts/test.sh                                 # unit tests (plain `swift test --no-parallel` with Xcode)
swift run Hopla --selftest /tmp/hopla-selftest    # full visits in the real panel: must print "Tout est OK"
swift run Hopla --render /tmp/hopla-renders       # boards to review art changes
```

Every pull request runs the build, the unit tests, the self-test and the boards on GitHub Actions; the boards
are attached to the run so reviewers can see your creature.

## Avatars

An avatar is one JSON file. The easiest way to make one is the editor (Settings → Avatar → Customize…),
which saves it to `~/Library/Application Support/Hopla/Avatars/`. You can also write it by hand:

```json
{
  "id": "ocean",
  "name": "Océan",
  "style": "watercolor",
  "shape": "round",
  "ears": "none",
  "extras": ["gills", "tentacles"],
  "hand": "splayed",
  "palette": {
    "body": "#9AD0FF", "belly": "#E8F5FF", "limbs": "#6BB3F0", "outline": "#1F4E79",
    "cheeks": "#FF9DAE", "eyes": "#10202E", "accent": "#3FA3C8"
  }
}
```

Only `id`, `name` and `palette` are required. Available values:

| Field | Values |
|---|---|
| `style` | `classic`, `ligneClaire`, `sketch`, `rubberHose`, `cartoon`, `pixel`, `lcd`, `clay`, `watercolor`, `neon`, `paper` |
| `shape` | `round`, `apple`, `tall`, `square`, `blob`, `cloud`, `pear`, `berry`, `lemon`, `ghost`, `egg`, `flame`, `drop`, `rock` |
| `ears` | `none`, `cat`, `bunny`, `bear`, `fox`, `mouse`, `elephant`, `bat`, `pointy` |
| `topper` | `none`, `sprout`, `antenna`, `beret`, `leaf`, `mushroomCap`, `tuft`, `bolt` |
| `belly` | `none`, `oval`, `large`, `muzzle` |
| `pattern` | `none`, `stripes`, `band`, `facePatch`, `spots`, `ribs`, `cleft`, `seeds`, `patches`, `zebra`, `drips`, `bandages`, `stars`, `cracks`, `chest`, `eggCrack`, `grooves`, `rivets`, `glitch`, `marks`, `swirl` |
| `tail` | `none`, `fox`, `dino`, `dragon` |
| `extras` | any of `cyclops`, `threeEyes`, `eyeStalks`, `fangs`, `teeth`, `horns`, `unicornHorn`, `noseHorn`, `ossicones`, `antennae`, `propellers`, `stem`, `leafCrown`, `calyx`, `forelock`, `crest`, `flame`, `spout`, `mane`, `fur`, `beard`, `whiskers`, `trunk`, `nostrils`, `frill`, `plates`, `gills`, `wings`, `bugWings`, `shell`, `tentacles`, `nineTails` |
| `hand` / `foot` | `ball`, `mitten`, `paw`, `claw`, `glove`, `threeFinger`, `talon`, `stubby`, `splayed`, `pincer`, `hoof`, `shoe`, `sneaker`, `boot` (omit to use the style's default) |
| `palette` | hex colors; optional `pattern`, `hands`, `feet`, `horns` |

To propose a built-in creature, add it to `Sources/Hopla/Core/Catalog.swift` and attach the `--render`
catalog board to your pull request.

## Exercises & routes

Moves are keyframed poses in `Sources/Hopla/Rig/Moves.swift`: arm angles (shoulder/elbow), foot positions
(the legs solve themselves), body lean, squash & stretch and the face. Register the exercise in
`Sources/Hopla/Core/Exercises.swift` (titles and instructions in French and English, posture, body zone),
then use it in the pre-recorded routes of `RouteBook`.

## Translations

Every string is written in place as `tr("Français", "English")`. Adding a language means adding a
parameter to `tr` and a case to `AppLanguage`.
