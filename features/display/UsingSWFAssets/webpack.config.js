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
			"openfl": path.resolve (__dirname, "node_modules/openfl/lib/openfl")
		}
	},
	module: {
		rules: [
			{
				test: /\.hxml$/,
				loader: 'haxe-loader',
			},
			{
				test: /\.swf$/,
				loader: 'swf-loader'
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