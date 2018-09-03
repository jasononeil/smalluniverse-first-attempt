package smalluniverse;

import buddy.*;
import smalluniverse.SUMacro.jsx;
import js.Browser.*;

using buddy.Should;

class TestSUMacro extends BuddySuite {
	public function new() {
		describe("SUMacro", {
			it("should let you use JSX macros on both client and server", {
				var name = "Jason";
				var div = jsx('<div>${name}</div>');
				jsx('<section>${div}</section>');
			});

			var expected = '<div id="myreact">My React</div>';

			#if client
			it("should create a valid react element when on the client", {
				var container = document.createElement('div');
				var div = jsx('<div id="myreact">My React</div>');
				react.ReactDOM.render(div, container);
				container.innerHTML.should.be(expected);
			});
			#end

			#if server
			it("should create a component that is renderable on the server", {
				var div = jsx('<div id="myreact">My React</div>');
				div.renderToString().should.be(expected);
			});
			#end
		});
	}
}
