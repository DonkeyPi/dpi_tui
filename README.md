# DonkeyPi Tui

## Controls

- Label, single line
- Frame, no children
- Button
- Checkbox
- Input, single line, length limited by size, no scrolling.
- Radio, String.Chars items only, no scrolling
- Select, String.Chars items only 
- Panel

## Focus

- Children get focused updated on appending to parent.
- Panels cache focusable state of children on tree building.
- Refocus/recalculate recursively cleans the focus lossing branch.
- There must not be two focused controls at any time.

## Modals

- Modals capture events when visible.
- Modals are marked with root: true property.
- Events are wrapped as {:modal, modal_key, original_event} when a modal is active.
- Wrapped events traverse the key path until the panel with matching key.
- The matching modal panel unwraps and reemits the event.
- Modals are detect by the upgrading model visitor. 
- The key of the last visited visible non root modal gets cached.
- On rendering, since the `modal model is not cached`, the tree is traverse to find it.
- The modal model is rendered on top of a dimmed root model.
- The last visited and closest to root modal gets selected.
- No modal nesting is supported at this time.
- Support for nested modals requires keeping an stack for dimmed rendering.

## Shortcuts

- There is a fixed list of keys that can be shortcuts.
- Shortcut events are key events for keys in the shortcuts list.
- Shortcut events get wrapped as {:shortcut, key}.
- Shortcut events are broadcasted to all nodes on the model tree.
- Buttons with a matching shortcut get triggered.
- Shortcuts are not exclusibly associated to a single button.
- Multiple buttons can be triggered at once.
- Shortcuts are broadcasted without model inplace update.

## Canvas

- Canvas size is taken from size passed to term driver.
- Root panels can have a non zero origin and be non fullscreen.
- Modals can have a non zero origin and be non fullscreen as well.
- The region no covered by the root panel gets the term back color.
- Root panels can change bounds on the go.
- The uncovered regions must be painted back to terms default.
- Term has fixed defaults to white and black for fore and back colors.
- Modals are not clipped by the root panel.
