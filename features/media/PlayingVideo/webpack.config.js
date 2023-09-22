const path = require ("path");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
	entry: "./build.hxml",
	output: {
		path: path.resolve (__dirname, "dist"),
		filename: "app.js"
	},
	devtool: "source-map",
	resolve: {
		alias: {
			"openfl": path.resolve (__dirname, "node_modules/openfl/lib/openfl"),
			"motion": path.resolve (__dirname, "node_modules/actuate/lib/motion")
		}
	},
	module: {
		rules: [
			{
				test: /\.hxml$/,
				loader: 'haxe-loader',
			}
		]
	},
	plugins: [
		new CopyWebpackPlugin({
			patterns: [
				"public"
			]
		})
	]
};