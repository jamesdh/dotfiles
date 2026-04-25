/**
 * Creates new macOS desktop spaces via Mission Control UI scripting.
 * Requires Accessibility permissions for the controlling app (e.g. Terminal/iTerm).
 *
 * Usage:
 *   osascript -l JavaScript create_space.scpt           # Create 1 space
 *   osascript -l JavaScript create_space.scpt 3         # Create 3 spaces
 *   osascript -l JavaScript create_space.scpt list      # List current space names
 *   osascript -l JavaScript create_space.scpt debug     # Dump Mission Control UI hierarchy
 */

ObjC.import('stdlib');

function openMissionControl() {
    var se = Application('System Events');
    // Control+Up Arrow is the default Mission Control shortcut
    se.keyCode(126, { using: 'control down' });
}

function closeMissionControl() {
    var se = Application('System Events');
    se.keyCode(53); // Escape
}

/**
 * Recursively dump UI element hierarchy for debugging.
 */
function dumpElement(el, depth) {
    if (depth > 6) return '';
    var indent = '  '.repeat(depth);
    var lines = [];

    try {
        var role = el.role();
        var name = '';
        var desc = '';
        try { name = el.name() || ''; } catch(e) {}
        try { desc = el.description() || ''; } catch(e) {}

        var label = role;
        if (name) label += ' "' + name + '"';
        if (desc && desc !== name) label += ' [' + desc + ']';
        lines.push(indent + label);

        var children = el.uiElements();
        for (var i = 0; i < children.length; i++) {
            lines.push(dumpElement(children[i], depth + 1));
        }
    } catch(e) {
        lines.push(indent + '(error: ' + e.message + ')');
    }

    return lines.join('\n');
}

/**
 * Collect space names by finding buttons within the Spaces Bar whose name
 * looks like a desktop (e.g. "Desktop 1", "Desktop 2").
 */
function collectSpaceNames(dock) {
    var names = [];

    function walk(el, depth) {
        if (depth > 6) return;
        try {
            var role = el.role();
            var name = '';
            try { name = el.name() || ''; } catch(e) {}
            if (role === 'AXButton' && /^Desktop\s/i.test(name)) {
                names.push(name);
            }
            var children = el.uiElements();
            for (var i = 0; i < children.length; i++) {
                walk(children[i], depth + 1);
            }
        } catch(e) {}
    }

    // Prefer searching within "Spaces Bar" group if it exists
    try {
        var groups = dock.groups();
        for (var i = 0; i < groups.length; i++) {
            var spacesBar = findGroupByName(groups[i], 'Spaces Bar');
            if (spacesBar) {
                walk(spacesBar, 0);
                if (names.length > 0) return names;
            }
        }
    } catch(e) {}

    // Fallback: search entire Dock UI
    walk(dock, 0);
    return names;
}

/**
 * Search for the "Add Desktop" button by walking the Dock process UI tree.
 * Tries several known patterns across macOS versions.
 */
function findAddButton(dock) {
    // Strategy 1: Look for a button whose name or description contains "add" (case-insensitive)
    var found = findButtonByPattern(dock, /add/i, 0);
    if (found) return found;

    // Strategy 2: Look within a "Spaces Bar" group specifically
    try {
        var groups = dock.groups();
        for (var i = 0; i < groups.length; i++) {
            var spacesBar = findGroupByName(groups[i], 'Spaces Bar');
            if (spacesBar) {
                var buttons = spacesBar.buttons();
                for (var b = 0; b < buttons.length; b++) {
                    var btn = buttons[b];
                    var bName = '';
                    var bDesc = '';
                    try { bName = btn.name() || ''; } catch(e) {}
                    try { bDesc = btn.description() || ''; } catch(e) {}
                    if (/add/i.test(bName) || /add/i.test(bDesc)) return btn;
                }
                // If there are buttons but none match "add", the add button
                // is often the last one outside the spaces list
                if (buttons.length > 0) return buttons[buttons.length - 1];
            }
        }
    } catch(e) {}

    return null;
}

/**
 * Recursively search for a button whose name or description matches a pattern.
 */
function findButtonByPattern(el, pattern, depth) {
    if (depth > 6) return null;

    try {
        var role = el.role();
        if (role === 'AXButton') {
            var name = '';
            var desc = '';
            try { name = el.name() || ''; } catch(e) {}
            try { desc = el.description() || ''; } catch(e) {}
            if (pattern.test(name) || pattern.test(desc)) return el;
        }

        var children = el.uiElements();
        for (var i = 0; i < children.length; i++) {
            var found = findButtonByPattern(children[i], pattern, depth + 1);
            if (found) return found;
        }
    } catch(e) {}

    return null;
}

/**
 * Recursively search for a group with a given name.
 */
function findGroupByName(el, targetName, depth) {
    if (depth === undefined) depth = 0;
    if (depth > 6) return null;

    try {
        var role = el.role();
        var name = '';
        try { name = el.name() || ''; } catch(e) {}
        if ((role === 'AXGroup' || role === 'AXList') && name === targetName) return el;

        var children = el.uiElements();
        for (var i = 0; i < children.length; i++) {
            var found = findGroupByName(children[i], targetName, depth + 1);
            if (found) return found;
        }
    } catch(e) {}

    return null;
}

function run(argv) {
    var mode = 'create';
    var count = 1;

    if (argv.length > 0) {
        if (argv[0] === 'debug') {
            mode = 'debug';
        } else if (argv[0] === 'list') {
            mode = 'list';
        } else {
            count = parseInt(argv[0], 10);
            if (isNaN(count) || count < 1) count = 1;
        }
    }

    var se = Application('System Events');

    // Open Mission Control
    openMissionControl();
    delay(1);

    var dock = se.processes.byName('Dock');

    if (mode === 'list') {
        var names = collectSpaceNames(dock);
        closeMissionControl();
        return names.join('\n');
    }

    if (mode === 'debug') {
        var output = 'Mission Control UI Hierarchy (Dock process):\n\n';
        try {
            var groups = dock.groups();
            output += 'Found ' + groups.length + ' top-level group(s)\n\n';
            for (var i = 0; i < groups.length; i++) {
                output += dumpElement(groups[i], 0) + '\n';
            }
        } catch(e) {
            output += 'Error reading groups: ' + e.message + '\n';
            output += '\nFull process dump:\n';
            output += dumpElement(dock, 0);
        }
        closeMissionControl();
        return output;
    }

    // Find the add button
    var addButton = findAddButton(dock);

    if (!addButton) {
        closeMissionControl();
        console.log(
            'Could not find the "Add Desktop" button.\n' +
            'Run with "debug" argument to inspect the UI hierarchy:\n' +
            '  osascript -l JavaScript create_space.scpt debug'
        );
        $.exit(1);
    }

    // Click the add button for each requested space
    for (var i = 0; i < count; i++) {
        try {
            addButton.click();
        } catch(e) {
            closeMissionControl();
            console.log('Failed to click add button on space ' + (i + 1) + ': ' + e.message);
            $.exit(1);
        }
        if (i < count - 1) delay(0.5);
    }

    delay(0.3);
    closeMissionControl();

    return 'Created ' + count + ' space(s)';
}
