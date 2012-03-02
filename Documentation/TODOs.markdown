#TODOs

---

### UI
* check special cases (backslash, typing inside #### etc…)
* inside of `<code>` spans, the scrolling does not work, because the anchor element is escaped (and appears in the text) 
* allow anchors inside the document and links that jump to the anchors in both views
	* best would be to just allow a "blind link target" with a simple syntax (e.g. just brackets) and a way to reference that target in the standard mdown link tag:
	`This is some {interesting text} I would like to link to [here](interesting_text).`
	* ATM there is a problem that anchor-only links point to a location in the resource folder of the app bundle
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

* create the possibility to include CSSs for different media
	* identify by file name, e.g., _style_screen.css_ and _style_print.css_

### File Format

I would like to support storing the selected css with the markdown, so that it opens the same way it was edited last. That would require defining a subtype of the `net.daringfireball.markdown` UTI and developing an own quick look and spotlight plugin.
both seems like a lot of work but also a nice idea.

* Questions
	* should the css be stored in the file or just the name of it?
		* __Name:__ keeps the text readable but does not work when sent to machine where the CSS is not available
		* __Full:__ the opposite ;)
	* the plugins must be fast… what do we use to compile?
	* it seems even easier to make a bundle, containing a thumbnail, the text, and the CSS
		* this again defeats the purpose of simple text files :)


