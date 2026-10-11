import type { Register } from 'claude-code'

import { EMOTES } from './emotes.gen'
import { emotify } from './emotify'

export const register: Register = on => {
  // undefined = not asked yet. Module variables die on reload, the store and env do not.
  let hasFont: boolean | undefined
  let isOn: boolean | undefined

  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'emotes',
      description: 'Toggle Twitch emote rendering, or list the emotes the font has',
      argumentHint: '[on|off|list]',
    })
    return next(e)
  })

  on('command.run', { command: 'emotes' }, async ($, e) => {
    const arg = e.args.trim()
    if (arg === 'list') return { text: Object.keys(EMOTES).join(' ') }
    isOn = arg === 'on' ? true : arg === 'off' ? false : !((await $.store.get('isOn')) ?? true)
    await $.store.set('isOn', isOn)
    $.ui.invalidate('ui.render')
    return { text: `Twitch emotes ${isOn ? 'on' : 'off'}.` }
  })

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    if (e.surface !== 'terminal') return next(e)
    // Only wezterm is configured with the emote font; anywhere else the glyphs are tofu
    hasFont ??= (await $.env.get('TERM_PROGRAM')) === 'WezTerm'
    if (!hasFont) return next(e)
    isOn ??= ((await $.store.get('isOn')) ?? true) === true
    if (!isOn) return next(e)
    return next({ ...e, props: { ...e.props, text: emotify(e.props.text) } })
  })
}
