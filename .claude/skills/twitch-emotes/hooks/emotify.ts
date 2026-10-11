import { EMOTES } from './emotes.gen'

// The glyph is 1 row tall and as wide, ~2.4 cells in Iosevka, and the font centers it in 3
// (emotefont.py CELLS). wezterm only lets a glyph spill out of its cell when the NEXT cell is
// a real space (allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"), NBSP does not
// count. The third cell is a braille blank: draws nothing, but is not whitespace, so neither
// markdown (two trailing spaces = hard break) nor the renderer's end-of-block trim eats the
// space the glyph needs after it. Trimmed pad = emote squeezed into one cell.
export const PAD = ' \u2800'

const LEAD = '([{"\'*_~'
const TRAIL = '.,!?;:)]}"\'*_~'

function swapToken(token: string): string {
  let start = 0
  while (start < token.length && LEAD.includes(token[start]!)) start++
  // Longest match first, so `D:` wins before its colon gets peeled off as punctuation
  for (let end = token.length; end > start; end--) {
    const glyph = EMOTES[token.slice(start, end)]
    if (glyph !== undefined) return token.slice(0, start) + glyph + PAD + token.slice(end)
    if (!TRAIL.includes(token[end - 1]!)) break
  }
  return token
}

function swapProse(prose: string): string {
  // Odd entries are the whitespace runs, kept as written
  const parts = prose.split(/(\s+)/)
  for (let i = 0; i < parts.length; i += 2) parts[i] = swapToken(parts[i]!)
  return parts.join('')
}

/** Emote names standing as their own word become glyphs; code blocks and `code spans` are left alone. */
export function emotify(markdown: string): string {
  const lines = markdown.split('\n')
  let fence: string | undefined
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]!
    const mark = /^\s*(`{3,}|~{3,})/.exec(line)?.[1]
    if (fence !== undefined) {
      if (mark !== undefined && mark[0] === fence[0] && mark.length >= fence.length) fence = undefined
      continue
    }
    if (mark !== undefined) {
      fence = mark
      continue
    }
    // Odd entries are inline code spans
    const parts = line.split(/(`+[^`]*`+)/)
    for (let j = 0; j < parts.length; j += 2) parts[j] = swapProse(parts[j]!)
    lines[i] = parts.join('')
  }
  return lines.join('\n')
}
