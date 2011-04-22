/* Simple JavaScript Inheritance
 * By John Resig http://ejohn.org/
 * MIT Licensed.
 */

(function () {
	var initializing = false,
	fnTest = /xyz/.test(function () {
		var xyz;
	}) ? /\binherited\b/: /.*/;
	this.Class = function () {};

	Class.extend = function (prop) {
		//save referrence on the root prototype object
		var inherited = this.prototype;
		/*
		 * create instance object
		 * who will be new instance's prototype, 
		 * this constructor
		 */
		initializing = true;
		var prototype = new this();
		initializing = false;

		/*
		 * extends the prototype of the new properties
		 * and check for the presence inheritance.
		 * if exist inheritance then change original function
		 * on the anonymous function, where we set inherited on the
		 * parent prototype
		 */
		for (var name in prop) {
			prototype[name] = typeof prop[name] == "function" && typeof inherited[name] == "function" && fnTest.test(prop[name]) ? (function (name, fn) {
				return function () {
					var tmp = this.inherited;
					this.inherited = inherited[name];
					var ret = fn.apply(this, arguments);
					this.inherited = tmp;
					return ret;
				};
			})(name, prop[name]) : prop[name];
		}

		function Class() {
			if (!initializing && this.init) {
				this.init.apply(this, arguments);
			}
		}

		Class.prototype = prototype;
		Class.prototype.constructor = Class;
		Class.extend = arguments.callee;
		return Class;
	};
})();
