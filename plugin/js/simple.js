/*
 * App is simple javascript "object library". It provide some methods
 * who allow work with XPCOM, JSON, UTF8
 */
var app = {
	Cc: Components.classes,
	Ci: Components.interfaces,
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
	}
};
/*
 * This function responsible for translate.
 * @params [hl, tl, text*]
 */
(function (args) {
  var hl = args[0];
  var tl = args[1];
  var query = args.slice(2);

	var Settings = {
	  langpair: hl+"|"+tl,
		hl: hl||"en",
		tl: tl||"ru",
		sl: hl||"en"
	};

	var st = Settings;
	//var url = "http://translate.google.com/translate_a/t?client=t&text=" + encodeURIComponent(query) + "&hl=" + st.hl + "&sl=" + st.sl + "&tl=" + st.tl + "&multires=1&otf=1&trs=1&sc=1";
	var url = "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=" + encodeURIComponent(query) + "&langpair=" + encodeURIComponent(st.langpair);

	var xhr = app.Cc["@mozilla.org/xmlextras/xmlhttprequest;1"].getService(app.Ci.nsIXMLHttpRequest);
	xhr.onload = function () {
		try {
			if (xhr.readyState == 4) {
				if (xhr.status == 200) {
				  var text = JSON.parse(xhr.responseText);
					dump(app.Utf8.encode(text.responseData.translatedText));
				} else {
					dump("Error loading...");
				}
			}
		} catch(e) {
			dump("ERROR: " + e);
		}
	};

	xhr.onerror = function (event) {};
	xhr.open("POST", url, false);
	xhr.send(null);

})(arguments);
