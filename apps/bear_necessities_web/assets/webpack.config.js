const path = require("path");
const glob = require("glob");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
var SpritesmithPlugin = require("webpack-spritesmith");

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: {
    "./js/app.js": ["./js/app.js"].concat(glob.sync("./vendor/**/*.js"))
  },
  output: {
    filename: "app.js",
    path: path.resolve(__dirname, "../priv/static/js")
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader"
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, "style-loader", "css-loader"]
      },
      {test: /\.gif$/, use: [
          "file-loader?name=i/[hash].[ext]"
      ]}
    ]
  },
  resolve: {
    modules: ["node_modules", "spritesmith-generated"]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: "../css/app.css" }),
    new CopyWebpackPlugin([{ from: "static/", to: "../" }]),
    new SpritesmithPlugin({
      src: {
        cwd: path.resolve(__dirname, "static/images/bear"),
        glob: "*.gif"
      },
      target: {
        image: path.resolve(__dirname, "static/spritesmith-generated/sprite.gif"),
        css: path.resolve(__dirname, "css/spritesmith-generated/sprite.css")
      },
      apiOptions: {
        cssImageRef: "~sprite.gif"
      }
    })
  ]
});
