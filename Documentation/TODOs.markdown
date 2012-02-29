#TODOs

---

### UI
* check special cases (backslash, typing inside #### etc…)
* inside of `<code>` spans, the scrolling does not work, because the anchor element is escaped (and appears in the text) 
* allow anchors inside the document and links that jump to the anchors in both views
	* best would be to just allow a "blind link target" with a simple syntax (e.g. just brackets) and a way to reference that target in the standard mdown link tag:
	`This is some {interesting text} I would like to link to [here](interesting_text).`
* Last line in textview looks truncated---maybe need an extra line?
* Space cheating does not work anymore because of the precedence of the selection changed delegate over the text changed one

###Architecture

###Export

* Export to ePub

* Check if there is an alternative to `writePDFInsideRect:(NSRect)aRect toPasteboard:(NSPasteboard *)pboard`

* Find a way to support pagination for PDFs or eBook formats

* QuickLook for mdown

* CSS selection should be saved (per doc / per user pref?)

* do not inline the CSS for exports other than HTML!

