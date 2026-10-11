import { expect, mock, test } from 'claude-code/testing'

import { EMOTES } from './emotes.gen'
import { emotify, PAD } from './emotify'

const g = (name: string) => EMOTES[name]! + PAD

test('swaps a lone emote name', async () => {
  expect(emotify('surely this works Clueless')).toBe(`surely this works ${g('Clueless')}`)
})

test('the pad survives a trim', async () => {
  expect(emotify('gg EZ').trimEnd()).toBe(`gg ${g('EZ')}`)
})

test('swaps neighbours separately', async () => {
  expect(emotify('Pepega Clap')).toBe(`${g('Pepega')} ${g('Clap')}`)
})

test('keeps punctuation around the name', async () => {
  expect(emotify('lol KEKW.')).toBe(`lol ${g('KEKW')}.`)
  expect(emotify('(forsenE)')).toBe(`(${g('forsenE')})`)
  expect(emotify('**Pog**')).toBe(`**${g('Pog')}**`)
})

test('D: is an emote, a drive letter is not', async () => {
  expect(emotify('you deleted prod D:')).toBe(`you deleted prod ${g('D:')}`)
  expect(emotify('D:, really')).toBe(`${g('D:')}, really`)
  expect(emotify('D:\\games and D:/games')).toBe('D:\\games and D:/games')
})

test('leaves partial words and other casing alone', async () => {
  const text = 'Pogchamp KEKWait kekw monkaS.png xPepega'
  expect(emotify(text)).toBe(text)
})

test('leaves code alone', async () => {
  const text = ['`KEKW` and `a KEKW b`', '```c', 'int KEKW = 1; // Pepega', '```', '~~~', 'Pog', '~~~'].join('\n')
  expect(emotify(text)).toBe(text)
  expect(emotify('`x` KEKW `y`')).toBe(`\`x\` ${g('KEKW')} \`y\``)
  expect(emotify('```\nKEKW\n```\nKEKW')).toBe(`\`\`\`\nKEKW\n\`\`\`\n${g('KEKW')}`)
})

test('keeps whitespace and newlines as written', async () => {
  expect(emotify('a  KEKW\n\n- Pog\tb')).toBe(`a  ${g('KEKW')}\n\n- ${g('Pog')}\tb`)
})

const reply = { text: 'it works Pog', isFirstOfReply: true }

for (const [term, want] of [['WezTerm', `it works ${g('Pog')}`], ['vscode', 'it works Pog']] as const) {
  test(`draws ${term === 'WezTerm' ? 'glyphs' : 'plain names'} under TERM_PROGRAM=${term}`, async ($, on) => {
    mock.env(on, { TERM_PROGRAM: term })
    mock.store(on)
    let drawn: string | undefined
    on('ui.render', { component: 'AssistantMessage' }, ($$, e) => {
      drawn = e.props.text
      const { Text } = $$.ui.resolve(e)
      return <Text>{e.props.text}</Text>
    })
    await $.ui.mount({ plugin: 'twitch-emotes', surface: 'terminal', component: 'AssistantMessage', props: reply })
    expect(drawn).toBe(want)
  })
}
