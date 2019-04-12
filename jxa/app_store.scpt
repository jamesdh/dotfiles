var app = Application("App Store");
app.includeStandardAdditions = true;
app.activate();

/* Trying to make it actually open the login dialog...
var store = Application("System Events").processes["App Store"];
store.windows[0].splitGroups[0].buttons[0].click();
*/