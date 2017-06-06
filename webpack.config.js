var path = require('path');

module.exports = {
    entry: './client.hxml',
    output: {
        path: __dirname + "/www/js",
        filename: 'react-test.bundle.js'
    },
    module: {
        rules: [
            {
                test: /\.hxml$/,
                loader: 'haxe-loader',
            },
            {
                test: /\.less$/,
                use: [
                    'style-loader',
                    { loader: 'css-loader', options: { importLoaders: 1 } },
                    { loader: 'less-loader', options: { strictMath: true, noIeCompat: true } }
                ]
            }
        ]
    },
    devServer: {
        contentBase: "./www",
        overlay: true,
        proxy: {
            "/": {
                changeOrigin: true,
                target: "http://localhost:2000"
            }
        },
        publicPath: "/js/"
    },
};
