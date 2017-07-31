import smalluniverse.UniversalPage;
import smalluniverse.UniversalComponent;
import smalluniverse.SUMacro.jsx;
#if server
	import sys.io.File;
	import haxe.Json;
#elseif client
	import js.Browser;
	import js.html.*;
#end
using tink.CoreApi;

enum HelloActions {
	GetOlder;
	ChangeName(newName:String);
}

typedef HelloParams = {location:String};

typedef HelloProps = {name:String, location:String, age:Int};

class HelloPage extends UniversalPage<HelloActions, HelloParams, HelloProps, {}, {}> {

	public function new() {
		super(new HelloBackendApi());
		this.head.addScript('js/react-test.bundle.js');
		this.head.setTitle('Hello!');
	}

	override function render():UniversalElement {
		return jsx('<div>
			<h1 onClick=${clickHeader}>Hello ${this.props.name}</h1>
			<h2 onClick=${clickHeader2}><em>How does it feel being <strong>${""+this.props.age}</strong> years old?</em></h2>
			<p>Nice to meet you! <b>:)</b> - welcome to ${this.props.location}</p>
			<input onKeyUp=${keyup} />
		</div>');
	}

	@:client
	function clickHeader() {
		trigger(GetOlder).handle(function (_) {
			Browser.alert('Successfully made you older, you are now ${props.age} years old');
		});
	}

	@:client
	function clickHeader2() {
		get().handle(function (outcome:Outcome<{name:String, age:Int},Error>) {
			var newProps = outcome.sure();
			Browser.alert('Updating props with ${newProps.name}, ${newProps.age}');
		});
	}

	@:client
	function keyup(e:react.ReactEvent) {
		var target = cast (e.target, InputElement);
		trigger(ChangeName(target.value));
	}
}
