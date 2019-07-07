var path = require("path");

module.exports = {
  entry: {
    server: "./node.hxml",
    client: "./client.hxml"
    // "test-client": "./test-client.hxml"
    // 'test-server': './test-server.hxml',
  },
  output: {
    path: __dirname + "/www/js",
    filename: "[name].bundle.js"
  },
  module: {
    rules: [
      {
        test: /\.hxml$/,
        use: [{ loader: "haxe-loader", options: { delayForNonJsBuilds: 300 } }]
      },
      {
        test: /\.css$/,
        use: [
          "style-loader",
          { loader: "css-loader", options: { importLoaders: 1 } }
        ]
      }
    ]
  },
  devServer: {
    contentBase: "./www",
    overlay: true,
    port: 3333,
    proxy: {
      "/": {
        changeOrigin: true,
        target: "http://localhost:8080"
      }
    },
    publicPath: "/js/"
  }
};
