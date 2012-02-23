# Known Issues

This document contains bugs and known issues for _ThoMarkdown_.

---

## Export / Copy
### Export

* PDF
	* Visually OK
	* __Links don't work but look like links__

* HTML
	* All OK, if on local machine (CSS is referred by full path)
	* __Probably breaks, when transferred to different machine or user!__

* RTF
	* __CSS is not interpreted__
	* __Quote indents missing__
	* __horizontal lines are missing__
	* Links work

###Copy

* PDF representation (test: _Preview.app_)
	* Visually OK
	* __Links don't work but look like links__

* Webarchive representation (test: _Mail.app_)
	* Structure OK (indents etc.)
	* __Visual elements (block quote bars, code boxes) missing__

* RTF representation (test: _TextEdit.app_)
	* __CSS is not interpreted__
	* __Quote indents missing__
	* __horizontal lines are missing__
	* Links work

* HTML representation (test: __none__)
	* __Not tested!__

* Markdown plaintext representation (test: _TextMate.app_)
	* Works as intended

## Other Bugs

