/*
 * load base core file
 */
load("_base.js");
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
		this.forEach(text, function (str) {
			dump(this.Utf8.encode(str[0]));
		});
		return response;
	}
});

var gTrans = new GoogleTranslator(fromLang,toLang);
for(var i=1; i <= LEN; i++){
	var query = Array.prototype.slice.apply(text,[(i-1)*MAGICK_NUMBER,i*MAGICK_NUMBER]).join('');
	gTrans.translate(query);
}
