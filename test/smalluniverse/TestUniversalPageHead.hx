package smalluniverse;

import buddy.*;
import smalluniverse.UniversalPageHead;
using buddy.Should;

class TestUniversalPageHead extends BuddySuite {
	public function new() {
		describe("UniversalPageHead", {

			var head;
			beforeEach(function () {
				head = new UniversalPageHead();
				head.setTitle('My Page');
				head.addScript('common.bundle.js', false);
				head.addScript('app.bundle.js');
				head.addStylesheet('app.bundle.css');
				head.addLink('preload', 'font.woff');
				head.addMeta('keywords', 'small, universe');
				head.addMeta('description', 'test the head');
			});

			it("should correctly render a string", {
				var str = head.renderToString();
				str.should.contain('<title>My Page</title>');
				str.should.contain('<script src="common.bundle.js"></script>');
				str.should.contain('<script src="app.bundle.js" async></script>');
				str.should.contain('<link rel="stylesheet" href="app.bundle.css" />');
				str.should.contain('<link rel="preload" href="font.woff" />');
				str.should.contain('<meta name="keywords" content="small, universe" />');
				str.should.contain('<meta name="description" content="test the head" />');
			});

			#if client
			it("should correctly sync element state on the client", {
				var headElm = js.Browser.document.createHeadElement();
				headElm.innerHTML = head.renderToString();

				var oldTitle = headElm.querySelector('title');
				var oldCommonJs = headElm.querySelector('script[src="common.bundle.js"]');
				var oldAppJs = headElm.querySelector('script[src="app.bundle.js"]');
				var oldAppCss = headElm.querySelector('link[href="app.bundle.css"]');
				var oldPreload = headElm.querySelector('link[href="font.woff"]');
				var oldKeywords = headElm.querySelector('meta[name="keywords"]');
				var oldDescription = headElm.querySelector('meta[name="description"]');

				var newHead = new UniversalPageHead();
				newHead.setTitle('My Second Page');
				newHead.addScript('common.bundle.js', false);
				newHead.addScript('app2.bundle.js');
				newHead.addStylesheet('app.bundle.css');
				newHead.addStylesheet('app2.bundle.css');
				newHead.addLink('preload', 'font.woff');
				newHead.addMeta('description', 'second page');

				newHead.syncHeadToDocument(headElm);

				var newTitle = headElm.querySelector('title');
				var newCommonJs = headElm.querySelector('script[src="common.bundle.js"]');
				var newApp2Js = headElm.querySelector('script[src="app2.bundle.js"]');
				var newAppCss = headElm.querySelector('link[href="app.bundle.css"]');
				var newApp2Css = headElm.querySelector('link[href="app2.bundle.css"]');
				var newPreload = headElm.querySelector('link[href="font.woff"]');
				var newDescription = headElm.querySelector('meta[name="description"]');

				// Adding new items
				newTitle.should.not.be(null);
				newCommonJs.should.not.be(null);
				newApp2Js.should.not.be(null);
				newAppCss.should.not.be(null);
				newApp2Css.should.not.be(null);
				newPreload.should.not.be(null);
				newDescription.should.not.be(null);

				// Removing other items
				oldTitle.parentNode.should.be(null);
				oldAppJs.parentNode.should.be(null);
				oldKeywords.parentNode.should.be(null);

				// Keeping existing items that match
				oldCommonJs.should.be(newCommonJs);
				oldAppCss.should.be(newAppCss);
				oldPreload.should.be(newPreload);

				// Items should change
				oldTitle.should.not.be(newTitle);
				oldDescription.should.not.be(newDescription);
			});
			#end
		});
	}
}