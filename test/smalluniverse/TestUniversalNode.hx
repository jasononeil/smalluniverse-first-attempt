package smalluniverse;

import buddy.*;
#if server
import smalluniverse.SUServerSideComponent;
#end
import smalluniverse.SUMacro.jsx;

using buddy.Should;

class TestUniversalNode extends BuddySuite {
	public function new() {
		describe("UniversalNode", {
			function renderToString(node:UniversalNode):String {
				return node.renderToString();
			}

			it("should render null correctly", {
				renderToString(null).should.be('');
			});

			it("should render a null JSX entry correctly", {
				var nullValue:String = null;
				var nullNode = jsx('${nullValue}');
				renderToString(nullNode).should.be('');
			});

			it("should cast a String and render text correctly", {
				renderToString('Hello').should.be('Hello');
				renderToString(2).should.be('2');
				renderToString(3.1).should.be('3.1');
			});

			it("should render a JSX text-only string correctly", {
				var stringNode = jsx('Hello');
				renderToString(stringNode).should.be('Hello');
			});

			it("should render basic tags and attributes", {
				var node = jsx('<p id="my-paragraph">Hello</p>');
				renderToString(node).should.be('<p id="my-paragraph">Hello</p>');
			});

			it("should rename className to class", {
				var node = jsx('<p className="my-paragraph">Hello</p>');
				renderToString(node).should.be('<p class="my-paragraph">Hello</p>');
			});

			it("should correctly set CSS styles from a JS object", {
				var styles = {
					backgroundColor: "blue",
					fontSize: "24px"
				};
				var node = jsx('<p style=${styles}>Hello</p>');
				renderToString(node).should.be('<p style="background-color: blue; font-size: 24px;">Hello</p>');
			});

			it("should handle the React dangerouslySetInnerHTML attribute", {
				var content = {
					__html: 'Stranger <em>Danger!</em>'
				};
				var node = jsx('<p dangerouslySetInnerHTML=${content} id="para"></p>');
				renderToString(node).should.be('<p id="para">Stranger <em>Danger!</em></p>');
			});

			it("should handle value and defaultValue on a textarea", {
				var value = 'My <i>cool textarea</i>';
				function onChange(e) {}
				var ta1 = jsx('<textarea value=${value} onChange=${onChange}></textarea>');
				renderToString(ta1).should.be('<textarea>My &lt;i&gt;cool textarea&lt;/i&gt;</textarea>');

				var ta2 = jsx('<textarea defaultValue=${value}></textarea>');
				renderToString(ta2).should.be('<textarea>My &lt;i&gt;cool textarea&lt;/i&gt;</textarea>');
			});

			it("should ignore ref=, children= and on*= attributes", {
				function listener(e) {}
				var node = jsx('<div
					id="my-div"
					ref=${null}
					children=""
					onClick=${listener}
					onAnimationEnd=${listener}
				></div>');
				renderToString(node).should.be('<div id="my-div"></div>');
			});

			it("should handle self closing tags", {
				var area = jsx('<area id="area" />');
				renderToString(area).should.be('<area id="area">');

				var base = jsx('<base id="base" />');
				renderToString(base).should.be('<base id="base">');

				var br = jsx('<br id="br" />');
				renderToString(br).should.be('<br id="br">');

				var col = jsx('<table><colgroup><col id="col" /></colgroup></table>');
				renderToString(col).should.be('<table><colgroup><col id="col"></colgroup></table>');

				var embed = jsx('<embed id="embed" />');
				renderToString(embed).should.be('<embed id="embed">');

				var hr = jsx('<hr id="hr" />');
				renderToString(hr).should.be('<hr id="hr">');

				var img = jsx('<img id="img" />');
				renderToString(img).should.be('<img id="img">');

				var input = jsx('<input id="input" />');
				renderToString(input).should.be('<input id="input">');

				var keygen = jsx('<keygen id="keygen" />');
				renderToString(keygen).should.be('<keygen id="keygen">');

				var link = jsx('<link id="link" />');
				renderToString(link).should.be('<link id="link">');

				var meta = jsx('<meta id="meta" />');
				renderToString(meta).should.be('<meta id="meta">');

				var param = jsx('<param id="param" />');
				renderToString(param).should.be('<param id="param">');

				var source = jsx('<source id="source" />');
				renderToString(source).should.be('<source id="source">');

				var track = jsx('<track id="track" />');
				renderToString(track).should.be('<track id="track">');

				var wbr = jsx('<wbr id="wbr" />');
				renderToString(wbr).should.be('<wbr id="wbr">');
			});

			it("should render a component correctly", {
				var node = jsx('<TestComponent172 />');
				renderToString(node).should.be('<div>Class</div>');
			});

			it("should cast an array and render a node list correctly", {
				renderToString([jsx('<TestComponent172 />'), jsx('Hello'), jsx('<div>Hi</div>')]).should.be('<div>Class</div>Hello<div>Hi</div>');
			});
		});
	}
}

class TestComponent172 extends UniversalComponent<{}, {}> {
	override public function render() {
		return jsx('<div>Class</div>');
	}
}
