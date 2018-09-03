package smalluniverse;

#if client
import js.Browser.*;
import js.html.*;
#end

// TODO: see if we can use a component API like react-helmut, so instead of calling `head.setTitle()`
// you just include a `<UniversalPageHead><title>Something</title></UniversalPageHead>` somewhere.
class UniversalPageHead {
	var title = "";
	var links:Array<{
		rel:String,
		href:String,
		?type:String,
		?title:String
	}> = [];
	var scripts:Array<{src:String, async:Bool}> = [];
	var meta:Array<{name:String, content:String}> = [];

	public function new() {}

	public function setTitle(title:String) {
		this.title = title;
		return this;
	}

	public function addScript(src:String, ?async:Bool = true) {
		scripts.push({src: src, async: async});
		return this;
	}

	public function addStylesheet(url:String) {
		return addLink('stylesheet', url);
	}

	public function addLink(rel:String, href:String, ?type:String, ?title:String) {
		links.push({
			rel: rel,
			href: href,
			type: type,
			title: title
		});
		return this;
	}

	public function addMeta(name:String, content:String) {
		meta.push({name: name, content: content});
		return this;
	}

	public function renderToString() {
		var titleMarkup = '<title>$title</title>';
		var metaMarkup = [for (m in meta) '<meta name="${m.name}" content="${m.content}" />'].join("\n");
		var linkMarkup = [for (l in links) renderLink(l)].join("\n");
		var scriptMarkup = [for (s in scripts) '<script src="${s.src}"${s.async ? ' async' : ''}></script>'].join("\n");

		return titleMarkup + '\n' + metaMarkup + '\n' + linkMarkup + '\n' + scriptMarkup;
	}

	static function renderLink(l) {
		var type = (l.type != null) ? 'type="${l.type}" ' : '';
		var title = (l.title != null) ? 'title="${l.title}" ' : '';
		return '<link rel="${l.rel}" href="${l.href}" ${type}${title}/>';
	}

	#if client
	/**
		Update the current document's `<head>` element to be in sync with the title, meta, links and scripts specified in this `UniversalPageHead`.

		@param head (Optional) An alternative `<head>` element to use. Usually you should leave this unspecified, in which case, `document.head` will be used. This is only available for unit testing.
	**/
	public function syncHeadToDocument(?head:HeadElement) {
		if (head == null) {
			head = document.head;
		}

		// Sync title.
		var title = document.createTitleElement();
		title.innerText = this.title;
		reconcileElements(head, 'title', [title], function(t1, t2) return t1.innerText == t2.innerText);

		// Sync metas.
		var metaElms = [
			for (m in meta) {
				var elm = document.createMetaElement();
				elm.name = m.name;
				elm.content = m.content;
				elm;
			}
		];
		reconcileElements(head, 'meta', metaElms, attrsMatch.bind(['name', 'content']));

		// Sync links.
		var linkElms = [
			for (l in links) {
				var elm = document.createLinkElement();
				elm.rel = l.rel;
				elm.href = l.href;
				elm.type = l.type;
				elm.title = l.title;
				elm;
			}
		];
		reconcileElements(head, 'link', linkElms, attrsMatch.bind(['rel', 'href']));

		// Sync scripts.
		var scriptElms = [
			for (s in scripts) {
				var elm = document.createScriptElement();
				elm.src = s.src;
				elm.async = s.async;
				elm;
			}
		];
		reconcileElements(head, 'script', scriptElms, attrsMatch.bind(['src', 'async']));
	}

	function attrsMatch(attrs:Array<String>, e1, e2) {
		for (attr in attrs) {
			if (e1.getAttribute(attr) != e2.getAttribute(attr))
				return false;
		}
		return true;
	}

	function reconcileElements(head:HeadElement, tagName:String, elementsToSet:Iterable<Element>, match:Element->Element->Bool) {
		var elementsToKeep = [];
		var elms = head.querySelectorAll(tagName);
		var currentElements = [for (i in 0...elms.length) cast elms[i]];
		// Add any elements that are missing
		for (elmToSet in elementsToSet) {
			var match = Lambda.find(currentElements, match.bind(elmToSet));
			if (match != null) {
				elementsToKeep.push(match);
			} else {
				head.appendChild(elmToSet);
				elementsToKeep.push(elmToSet);
			}
		}
		// Go through and remove the elements that are left over and no longer needed.
		for (elm in currentElements) {
			if (elementsToKeep.indexOf(elm) == -1) {
				elm.parentNode.removeChild(elm);
			}
		}
	}
	#end
}
