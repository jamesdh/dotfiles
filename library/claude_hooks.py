#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = '''
---
module: claude_hooks
short_description: Merge hook groups into a Claude Code settings.json without clobbering it
description:
  - Ensures the given hook groups are present under C(hooks.<event>) in a Claude Code
    settings file (repo C(.claude/settings.json) or the user file), leaving every
    other key, event, and hook group in the file untouched. Tools such as
    C(growlrrr init) print a complete settings document; writing that with C(copy)
    would replace hooks other tools (Sideband, for one) have registered in the same
    file. This module adds only what is missing and reports unchanged otherwise.
options:
  path:
    description: The settings.json file to update. Created if missing.
    required: true
    type: path
  hooks:
    description:
      - Mapping of event name (C(Stop), C(UserPromptSubmit), ...) to a list of hook
        groups in Claude Code's own shape (C({"matcher": ..., "hooks": [{"type":
        "command", "command": ...}]})). Groups already present (compared for equality)
        are not duplicated.
    required: true
    type: dict
  replace:
    description:
      - Regular expression matched against each existing hook's C(command). A group
        containing a matching command is removed before the desired groups are added,
        so stale variants owned by the same tool (an old app id, a moved binary) are
        replaced rather than accumulated. Groups whose commands do not match are never
        touched.
    required: false
    type: str
'''

EXAMPLES = '''
- name: Register Growlrrr notification hooks
  claude_hooks:
    path: "{{ repo }}/.claude/settings.json"
    hooks: "{{ (grrr_claude_config.stdout | from_json).hooks }}"
    replace: '^grrr hook '
'''

RETURN = '''
changed:
  description: Whether the file was (or, in check mode, would be) modified.
  type: bool
'''

import copy
import json
import os
import re

from ansible.module_utils.basic import AnsibleModule


class HooksFormatError(ValueError):
    pass


def _matches(group, pattern):
    if pattern is None:
        return False
    for hook in group.get("hooks", []) or []:
        command = hook.get("command") if isinstance(hook, dict) else None
        if isinstance(command, str) and pattern.search(command):
            return True
    return False


def merge_hooks(settings, hooks, replace):
    """Return (merged_settings, changed). Neither input is mutated."""
    result = copy.deepcopy(settings) if settings else {}
    existing_hooks = result.setdefault("hooks", {})
    if not isinstance(existing_hooks, dict):
        raise HooksFormatError("'hooks' must be an object, found %s" % type(existing_hooks).__name__)
    pattern = re.compile(replace) if replace else None
    changed = False

    for event, desired_groups in hooks.items():
        current = existing_hooks.get(event, [])
        if not isinstance(current, list):
            raise HooksFormatError("'hooks.%s' must be a list, found %s" % (event, type(current).__name__))
        # Keep every group that is wanted or not ours; only stale owned groups go.
        # Wanted groups stay in place so an already-correct file is not reordered.
        kept = [g for g in current if g in desired_groups or not _matches(g, pattern)]
        for group in desired_groups:
            if group not in kept:
                kept.append(group)
        if kept != current:
            changed = True
            existing_hooks[event] = kept

    if not existing_hooks and "hooks" not in (settings or {}):
        del result["hooks"]
    return result, changed


def _load(path):
    if not os.path.exists(path):
        return {}, ""
    with open(path) as fh:
        text = fh.read()
    if not text.strip():
        return {}, text
    return json.loads(text), text


def main():
    module = AnsibleModule(
        argument_spec=dict(
            path=dict(type="path", required=True),
            hooks=dict(type="dict", required=True),
            replace=dict(type="str", required=False),
        ),
        supports_check_mode=True,
    )
    path = module.params["path"]

    try:
        settings, before = _load(path)
    except ValueError as exc:
        module.fail_json(msg="%s is not valid JSON: %s" % (path, exc))
    if not isinstance(settings, dict):
        module.fail_json(msg="%s must hold a JSON object" % path)

    try:
        merged, changed = merge_hooks(settings, module.params["hooks"], module.params["replace"])
    except (HooksFormatError, re.error) as exc:
        module.fail_json(msg="%s: %s" % (path, exc))

    after = json.dumps(merged, indent=2) + "\n"
    diff = dict(before=before, after=after, before_header=path, after_header=path)
    if changed and not module.check_mode:
        parent = os.path.dirname(path)
        if parent and not os.path.isdir(parent):
            os.makedirs(parent, 0o755)
        with open(path, "w") as fh:
            fh.write(after)
    module.exit_json(changed=changed, diff=diff)


if __name__ == "__main__":
    main()
