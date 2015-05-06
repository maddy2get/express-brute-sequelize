# Sequelize store for express-brute

Sequelize(MySQL) store adapter for the [express-brute](https://github.com/AdamPflug/express-brute).

## Installation

~~~
npm install express-brute-sequelize
~~~


## Usage

~~~javascript
var ExpressBrute = require('express-brute');
var SequelizeStore = require('express-brute-sequelize');
var Sequelize = require('sequelize');

var sequelize = new Sequelize('test', 'root', 'root', {
  host: "127.0.0.1",
  dialect: "mysql",
  logging: false
});

new SequelizeStore(sequelize, 'bruteStore', {}, function(store) {
	var bruteforce = new ExpressBrute(store);
	app.post('/session',
		bruteforce.prevent, // error 403 if too many requests for this route in short time
		function(req, res, next){
			res.send('Success!');
		}
	);
});

~~~

## Issue Reporting
If you have found a bug or if you have a feature request, please report them at this repository issues section.

## License
This project is licensed under the MIT license. See the [LICENSE](LICENSE.txt) file for more info.
