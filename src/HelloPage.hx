import smalluniverse.UniversalPage;
import smalluniverse.UniversalComponent;
import smalluniverse.SUMacro.jsx;
#if server
	import sys.io.File;
	import haxe.Json;
#elseif client
	import js.Browser;
#end
using tink.CoreApi;

class HelloPage extends UniversalPage<{name:String, age:Int}, {}, {}> {
	override function get():Promise<{name:String, age:Int}> {
		var json = File.getContent('props.json');
		var props:{name:String, age:Int} = Json.parse(json);
		return props;
	}

	override function render():UniversalElement {
		return jsx('<div>
			<h1 onClick=${clickHeader}>Hello ${this.props.name}</h1>
			<h2><em>How does it feel being <strong>${""+this.props.age}</strong> years old?</em></h2>
			<p>Nice to meet you! <b>:)</b></p>
		</div>');
	}

	@:serverAction public function addExplanationMark():Promise<String> {
		var json = File.getContent('props.json');
		var props:{name:String, age:Int} = Json.parse(json);
		props.age++;
		json = Json.stringify(props);
		File.saveContent('props.json', json);
		return Sys.getCwd();
	}

	@:client
	function clickHeader() {
		addExplanationMark().handle(function (outcome:Outcome<String,Error>) {
			var path = outcome.sure();
			Browser.alert('Executed at $path');
		});
	}
}
