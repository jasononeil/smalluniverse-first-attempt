package smalluniverse;

import smalluniverse.SUServerSideComponent;
import smalluniverse.SUMacro.jsx;
import monsoon.Request;
import monsoon.Response;
using StringTools;

class SmallUniverse {

    static var template:String = '<html>
        <head>
        </head>
        <body>
            <div id="smalluniverse_root">{BODY}</div>
            <script src="react-test.bundle.js"></script>
        </body>
    </html>';
    var app:Monsoon;

    public function new(monsoonApp:Monsoon) {
        this.app = monsoonApp;
    }

    public function addPage(route:String, page:Class<UniversalPage<Dynamic,Dynamic,Dynamic>>) {
        app.get(route, function (req:Request, res:Response) {
            var componentCls:Class<SUServerSideComponent<Dynamic,Dynamic,Dynamic>> = cast page;
            var component = SUServerSideNode.createNodeForComponent(componentCls, {name: "Jason"}, null);
            var html = template.replace('{BODY}', component.renderToString());
            res.send(html);
        });
    }
}
