# US-11-20: M11 PO demo — subtractive synth end-to-end

## Type

Demo / sign-off

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **PO**, I can run one **signed demo script** proving the subtractive synth milestone is shippable on a physical Android device.

## Demo script (~3 min)

1. **Add** Subtractive Synth on a new track (oscillator still available on another track).
2. **Play** tab → 8-voice chord on pads — no dropouts.
3. Strip **Osc** → dual saw + unison → **Mix** → noise + `am` mode.
4. **Filter** → LP12 envelope sweep → **Amp** → short pluck envelope.
5. **Fullscreen** → test note while editing cutoff.
6. **Library** → load **Warm Pad** preset → audible change.
7. **Glide** on → legato line on keyboard.
8. **Save** project → kill app → **reload** → preset + params intact.
9. Add **simple_oscillator** on track 2 → both instruments play together.

## Sign-off checklist

- [ ] All US-11-01 … US-11-09 acceptance criteria met
- [ ] No LFO UI or engine stubs shipped half-finished
- [ ] LP12 only — no hidden multimode filter in UI
- [ ] C++ golden tests green in CI
- [ ] Flutter analyze + widget tests green
- [ ] Deployed via `tools/flutter_deploy.ps1` on PO device

## Depends on

US-11-09

## Status

**Todo**
