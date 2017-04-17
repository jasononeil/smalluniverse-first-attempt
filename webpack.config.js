var path = require('path');

module.exports = {
    entry: './www/react-test.haxe.js',
    output: {
        path: __dirname + "/www",
        filename: 'react-test.bundle.js'
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                loader: 'babel-loader',
                exclude: [path.resolve(__dirname, "node_modules")],
                options: {
                    presets: ['react', 'es2015']
                }
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
    }
};
