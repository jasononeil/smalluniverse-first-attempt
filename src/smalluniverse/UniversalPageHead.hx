package smalluniverse;

class UniversalPageHead {
	var title = "";
	var stylesheets:Array<String> = [];
	var scripts:Array<{url:String, async:Bool}> = [];

	public function new() {}

	public function setTitle(title:String) {
		this.title = title;
		return this;
	}

	public function addScript(url:String, ?async:Bool=true) {
		scripts.push({url:url, async:async});
		return this;
	}

	public function addStylesheet(url:String) {
		stylesheets.push(url);
		return this;
	}

	public function renderToString() {
		var titleMarkup = '<title>$title</title>';
		var stylesheetMarkup = [for (s in stylesheets) '<link rel="stylesheet" href="$s" />'].join("\n");
		var scriptMarkup = [for (s in scripts) '<script src="${s.url}" ${s.async ? 'async' : ''}></script>'].join("\n");

		return titleMarkup + '\n' + stylesheetMarkup + '\n' + scriptMarkup;
	}
}
