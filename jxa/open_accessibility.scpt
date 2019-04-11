var app = Application("System Preferences");
app.includeStandardAdditions = true;
app.activate();
var snp = app.panes.whose({name: {_beginsWith: "Security"}})[0];
snp.anchors.whose({name: "Privacy_Accessibility"})[0].reveal();