/*
 * load base core file
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
/*
 * constants and settings
 */
var fromLang = arguments[0];
var toLang = arguments[1];
var text = arguments[2];

var MAGICK_NUMBER = 1000.0; //max length text for request
var LEN = Math.ceil(text.length/MAGICK_NUMBER);
/*
 * XPCOM base object
 */
var XPCOM = Class.extend({
	Cc: Components.classes,
	Ci: Components.interfaces,
	fstream: function () { //file-input-stream
		return this.Cc["@mozilla.org/network/file-input-stream;1"].createInstance(this.Ci.nsIFileInputStream);
	},
	fostream: function () { //file-output-stream
		return this.Cc["@mozilla.org/network/file-output-stream;1"].createInstance(this.Ci.nsIFileOutputStream);
	},
	cstream: function () { //convert-input-stream
		return this.Cc["@mozilla.org/intl/converter-input-stream;1"].createInstance(this.Ci.nsIConverterInputStream);
	},
	costream: function () { //convert-output-stream
		return this.Cc["@mozilla.org/intl/converter-output-stream;1"].createInstance(this.Ci.nsIConverterOutputStream);
	},
	hitch: function (scope, callback) {
		if (typeof callback === "string") {
			scope = scope || window;
			return function () {
				return scope[callback].apply(scope, arguments || []);
			}; // Function
		}
		return function () {
			return callback.apply(scope, arguments || []);
		};
	},
	Utf8: {
		encode: function (string) {
			return unescape(encodeURIComponent(string));
		},
		decode: function (utfstring) {
			return decodeURIComponent(escape(utfstring));
		}
	},
	fromJSON: {
		parse: function (json) {
			var inline = "",
			clnwl = json.split('\n');
			for (var i = 0; i < clnwl.length; i++) {
				inline = inline + clnwl[i];
			}
			var obj = JSON.parse(inline.replace(/,(?!\w+|\"|\{|\[|\s+)/g, '$&\"\"'));
			return obj;
		}
	},
	xhrPost: function (args) {
		var xhr = this.Cc["@mozilla.org/xmlextras/xmlhttprequest;1"].getService(this.Ci.nsIXMLHttpRequest);
		xhr.onload = function () {
			try {
				if (xhr.readyState == 4) {
					if (xhr.status == 200) {
						return args.load(xhr.responseText);
					} else {
						dump("Error loading...");
					}
				}
			} catch(e) {
				dump("ERROR: " + e);
			}
		};
		xhr.open("POST", args.url, false);
		xhr.send(args.data || null);
	},
	forEach: function (arr, callback, thisObject) {
		if (!arr) {
			return;
		}
		for (var i in arr) {
			if (arr.hasOwnProperty(i)) {
				var args = (arr.constructor == Array) ? [arr[i], i, arr] : [i, arr[i], arr];
				callback.apply(thisObject || this, args);
			}
		}
	},
	ccFile: function () {
		return this.Cc["@mozilla.org/file/local;1"].createInstance(this.Ci.nsILocalFile);
	},
	ccDir: function (PATH) {
		return this.Cc["@mozilla.org/file/directory_service;1"].getService(this.Ci.nsIProperties).get(PATH || "Home", this.Ci.nsIFile);
	},
	ccProcess: function () {
		return this.Cc["@mozilla.org/process/util;1"].createInstance(this.Ci.nsIProcess);
	},
	writeFile: function (file, data, ENCOD) {
		var foStream = this.fostream();
		// use 0x02 | 0x10 to open file for appending.
		foStream.init(file, 0x02 | 0x08 | 0x20, 0666, 0);
		var converter = this.costream();
		converter.init(foStream, ENCOD || "UTF-8", 0, 0);
		converter.writeString(data);
		converter.close(); // this closes foStream
		return this.simpleRead(file, ENCOD || null);
	},
	simpleRead: function (file, ENCOD) {
		var data = "",
		fstream = this.fstream(),
		cstream = this.cstream();
		fstream.init(file, -1, 0, 0);
		cstream.init(fstream, ENCOD || "UTF-8", 0, 0);
		(function () {
			var str = {};
			var read = 0;
			do {
				read = cstream.readString(0xffffffff, str); // read as much as we can and put it in str.value
				data += str.value;
			} while (read !== 0);
		})();
		cstream.close();
		return data;
	}
});
/*
 * Create Translator Class
 */
var GoogleTranslator = XPCOM.extend({
	/*
	 * definition language
	 * @hl = language of the text
	 * @tl = translation language
	 */
	init: function (hl, tl, sl) {
		this.hl = hl;
		this.tl = tl;
		this.sl = sl ? sl: hl;
	},
	url: "http://translate.google.com/translate_a/t",
	translate: function (text) {
		var urn = "?client=t&text=" + encodeURIComponent(text) + "&hl=" + this.hl + "&sl=" + this.sl + "&tl=" + this.tl + "&multires=1&otf=1&trs=1&sc=1";
		return this.xhrPost({
			url: String.concat(this.url, urn),
			load: this.hitch(this,"_didTranslate")
		});
	},
	_didTranslate: function (response) {
		var text = this.fromJSON.parse(response)[0];
		var file = this.ccDir("TmpD");
		file.append("test_translate.txt");
		if( !file.exists() || !file.isFile() ) {
			   file.create(this.Ci.nsIFile.FILE_TYPE, 0777);
		}
		this.forEach(text, function (str) {
			dump(this.Utf8.encode(str[0]));
			this.writeFile(file,str[0]);
		});
		return response;
	}
});

var gTrans = new GoogleTranslator(fromLang,toLang);
for(var i=1; i <= LEN; i++){
	var query = Array.prototype.slice.apply(text,[(i-1)*MAGICK_NUMBER,i*MAGICK_NUMBER]).join('');
	gTrans.translate(query);
}
