import monsoon.Monsoon;
import monsoon.Request;
import monsoon.Response;
import smalluniverse.SUMacro.jsx;

class Server {
	static var template = '
	<html>
		<head>
		</head>
		<body>
			<div id="container">{component}</div>
			<script src="react-test.bundle.js"></script>
		</body>
	</html>';

	static function main() {
		var app = new Monsoon();
		app.route('/', function (req:Request, res:Response) {
			var componentHtml = jsx('<HelloPage name="Jason" />').renderToString();
			var html = template.split('{component}').join(componentHtml);
			res.send(html);
		});
		app.listen(3000);
	}
}
