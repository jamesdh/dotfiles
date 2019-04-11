/**
 Checks if either Terminal or iTerm have "Full Disk Access" and prompts to add one if not.
 Without this some defaults settings will fail.
**/

var app = Application("System Preferences");
app.includeStandardAdditions = true;
app.activate();
var snp = app.panes.whose({name: {_beginsWith: 'Security'}})[0];
snp.anchors.whose({name: 'Privacy_AllFiles'})[0].reveal();

var prefs = Application("System Events").processes["System Preferences"];

var termFound = prefs.windows[0].tabGroups[0].groups[0].scrollAreas[0].tables[0].rows.whose({
	_or: [{
		_match: [ObjectSpecifier().uiElements[0].name, 'Terminal']
	},{
		_match: [ObjectSpecifier().uiElements[0].name, 'iTerm.app']	
	}]
	
})()

if(!termFound || termFound.length == 0) {
	app.activate();
	snp.authorize();
	prefs.windows[0].tabGroups[0].groups[0].groups[0].buttons[0].click();
} else {
	app.quit()
}
