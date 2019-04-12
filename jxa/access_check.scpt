/**
 Checks if either Terminal or iTerm have "Full Disk Access" and prompts to add one if not.
 Without this some defaults settings will fail.
**/
var curr = Application.currentApplication();
curr.includeStandardAdditions = true;
curr.activate();

var app = Application("System Preferences");
app.includeStandardAdditions = true;
app.activate();
var snp = app.panes.whose({name: {_beginsWith: 'Security'}})[0];
snp.anchors.whose({name: 'Privacy_Accessibility'})[0].reveal();

var prefs = Application("System Events").processes["System Preferences"];

var appNames = ['Terminal', 'Contexts', 'Divvy'];

var ok = true
for(var name of appNames) {
    var appsFound = prefs.windows[0].tabGroups[0].groups[0].scrollAreas[0].tables[0].rows.whose({
        _or: [{
			_match: [ObjectSpecifier().uiElements[0].name, name]
		},{
			_match: [ObjectSpecifier().uiElements[0].name, `${name}.app`]	
		}]
    })()
	ok = appsFound.length == 1 ? ok : false;
}

if(!ok) {
	app.activate();
    app.displayDialog('Add the following apps to Accessibility before continuing: \n - Contexts \n - Divvy \n - Terminal')
	snp.authorize();
	//prefs.windows[0].tabGroups[0].groups[0].groups[0].buttons[0].click();
    ObjC.import('stdlib');
    $.exit(1)
} else {
	app.quit()
}
