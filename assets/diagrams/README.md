# Diagrams

Rendered images for diagrams embedded in `README.md`.

GitHub's native mobile apps (iOS/Android) do not render ` ```mermaid ` fenced
code blocks — they show the raw source text instead. Only github.com in a
browser (desktop or mobile) renders Mermaid live. To make the README's hero
diagram display everywhere, its Mermaid source is committed here and
rendered ahead of time to a static SVG that `README.md` embeds as a normal
image. See `constitution/ARCHITECTURE.md`'s "Visual Architecture" section
for the full policy.

## Files

- `how-it-works.mmd`: Mermaid source for the diagram in README.md's "How It
  Works" section.
- `how-it-works.svg`: Rendered output, embedded directly in `README.md`.
- `mermaid-config.json`: Rendering config, reused verbatim from the
  constitution's own diagram setup — `htmlLabels: false` so node/edge text
  renders as native SVG `<text>` instead of HTML-in-`foreignObject`, `curve:
  "linear"` for straight edges instead of mermaid's default curvy bezier
  routing, and a muted `base`-theme palette (light blue/green node fills,
  gray hairline borders and lines) instead of mermaid's default
  yellow-cluster/purple-node theme.

Diagram design notes: the flow is kept one-directional (host GPU binding →
hypervisor passthrough → guest driver → container runtime → containers), no
feedback loops back into an earlier node. The RTX 4080 is deliberately drawn
with no outgoing edge into the passthrough chain — it stays on the host,
untouched, for the entire flow; that's the point of the whole setup.
`flowchart TD` (tall/narrow) is used rather than `LR` (wide/short): GitHub
scales the image to the column width, so a wide diagram shrinks its text to
near illegibility on a phone, while a tall one scales up and stays readable.

## Regenerating

After editing `how-it-works.mmd`, re-render the SVG:

```bash
npx --yes @mermaid-js/mermaid-cli \
  -i assets/diagrams/how-it-works.mmd -o assets/diagrams/how-it-works.svg \
  -b white -c assets/diagrams/mermaid-config.json
```

Commit both files together so the source and the rendered image never drift.
