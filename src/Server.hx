import haxe.crypto.Adler32;
import haxe.io.Bytes;
import monsoon.Monsoon;
import monsoon.Request;
import monsoon.Response;

class Server {
	static var template = '
	<html>
		<head>
		</head>
		<body>
			<div id="container"><h1 data-reactroot="" data-reactid="1" data-react-checksum="1751407853"><!-- react-text: 2 -->Hello <!-- /react-text --><!-- react-text: 3 -->Jason<!-- /react-text --><!-- react-text: 4 -->, <!-- /react-text --><em data-reactid="5"><!-- react-text: 6 -->or should I say <!-- /react-text --><strong data-reactid="7">JASON</strong></em></h1></div>
			<script src="react-test.bundle.js"></script>
		</body>
	</html>';

	static function main() {
		var app = new Monsoon();
		app.route('/', function (req:Request, res:Response) {
			res.send(template);
		});
		app.listen(3000);
	}
}
