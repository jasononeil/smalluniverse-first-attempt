package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
import react.ReactMacro;
import react.jsx.JsxSanitize;
import react.jsx.JsxParser;

using haxe.macro.ExprTools;

/**
	A collection of macros that are used to help make SmallUniverse work seamlessly on both Client-Side JS and Server-Side multi-platform.
**/
@:access(react.ReactMacro)
class SUMacro {
	/**
		Convert a JSX String into the

		The functions identically to `ReactMacro.jsx()` except that on the server-side we have a different output format that works cross-platform without React.

		See https://github.com/massiveinteractive/haxe-react#jsx for details.
	**/
	public static macro function jsx(expr:ExprOf<String>):Expr {
		if (Context.defined('display')) {
			return macro untyped ${expr};
		} else {
			#if (client)
			return ReactMacro.parseJsx(ExprTools.getValue(expr), expr.pos);
			#else
			// We need to use the JSX parser but process it in a way that is specific to server-side.
			return parseJsx(ExprTools.getValue(expr), expr.pos);
			#end
		}
	}

	/* PARSER  */
	#if macro
	static function parseJsx(jsx:String, pos:Position):Expr {
		jsx = JsxSanitize.process(jsx);
		var xml = try Xml.parse(jsx) #if (haxe_ver >= 3.3)
		catch (err:haxe.xml.Parser.XmlParserException) {
			var posInfos = Context.getPosInfos(pos);
			var realPos = Context.makePosition({
				file: posInfos.file,
				min: posInfos.min + err.position,
				max: posInfos.max + err.position,
			});
			Context.fatalError('Invalid JSX: ' + err.message, realPos);
		} #end
	catch (err:Dynamic) Context.fatalError('Invalid JSX: ' + err, err.pos ? err.pos : pos);

		var ast = JsxParser.process(xml);
		var expr = parseJsxNode(ast, pos);
		return macro($expr : smalluniverse.UniversalNode);
	}

	static function parseJsxNode(ast:JsxAst, pos:Position) {
		switch (ast) {
			case JsxAst.Text(value):
				return macro $v{value};

			case JsxAst.Expr(value):
				return Context.parse(value, pos);

			case JsxAst.Node(isHtml, path, attributes, jsxChildren):
				// parse type
				var type = isHtml ? macro $v{path[0]} : macro $p{path};
				type.pos = pos;

				// parse attributes
				var attrs = [];
				var spread = [];
				var key = null;
				var ref = null;
				for (attr in attributes) {
					var expr = ReactMacro.parseJsxAttr(attr.value, pos);
					var name = attr.name;
					if (name == 'key')
						key = expr;
					else if (name == 'ref')
						ref = expr;
					else if (name.charAt(0) == '.')
						spread.push(expr);
					else
						attrs.push({field: name, expr: expr});
				}

				var children = [for (child in jsxChildren) parseJsxNode(child, pos)];

				// inline declaration or createElement?
				if (ref != null)
					attrs.unshift({field: 'ref', expr: ref});
				if (key != null)
					attrs.unshift({field: 'key', expr: key});

				// We actually set the children property in SUServerSideNode.createNodeForComponent.
				// But we need to fake it here so ReactMacro knows it is provided.
				if (children.length > 0) {
					attrs.push({field: 'children', expr: macro($a{children} : Array<smalluniverse.UniversalNode>)});
				}
				var props = ReactMacro.makeProps(spread, attrs, pos);

				if (isHtml) {
					return macro @:privateAccess smalluniverse.SUServerSideComponent.SUServerSideNode.createNodeForHtml($type, $props, $a{children});
				} else {
					return macro @:privateAccess smalluniverse.SUServerSideComponent.SUServerSideNode.createNodeForComponent($type, $props, $a{children});
				}
		}
	}
	#end
}
