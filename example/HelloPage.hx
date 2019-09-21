import react.ReactComponent.ReactFragment;
import smalluniverse.UniversalPage;
import smalluniverse.UniversalNode;
import smalluniverse.HtmlElements.*;
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

class HelloPage extends UniversalPage<HelloActions, HelloProps, {}> {
	public function new(location:String) {
		super(new HelloBackendApi(location));
		this.head.addScript('/js/client.bundle.js');
		// In development mode, include this "server.bundle.js" stub so it reloads when the server is updated.
		this.head.addScript('/js/server.bundle.js');
		this.head.setTitle('Hello!');
	}

	override function render():UniversalNode {
		// It's a trade-off in plain-text readability vs editor happyness
		// JSX feels easier to read (maybe it's just familiarity?)
		// But with this format I get auto-completion, go-to-definition, hover-documentation etc
		return div([
			h1({onClick: clickHeader}, 'Hello ${this.props.name}'),
			h2({onClick: clickHeader2}, [
				em((['How does it feel being ', strong('${this.props.age}'), ' years old?'] : Array<ReactFragment>))
			]),
			p((['Nice to meet you! ', b(':)'), ' - welcome to ${this.props.location}'] : Array<ReactFragment>)),
			input({onKeyUp: keyup})
		]);
	}

	@:client
	function clickHeader() {
		trigger(GetOlder).handle(function(_) {
			Browser.alert('Successfully made you older, you are now ${props.age} years old');
		});
	}

	@:client
	function clickHeader2() {
		get().handle(function(outcome:Outcome<{name:String, age:Int}, Error>) {
			var newProps = outcome.sure();
			Browser.alert('Updating props with ${newProps.name}, ${newProps.age}');
		});
	}

	@:client
	function keyup(e:react.ReactEvent) {
		var target = cast(e.target, InputElement);
		trigger(ChangeName(target.value));
	}
}
