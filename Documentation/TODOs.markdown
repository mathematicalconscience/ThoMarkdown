#TODOs

---

### UI
* Synchronize view port of the web view to match currently edited location in the editor
	* prevent web view from becoming first responder (it catches spaces!)
	* check special cases (backslash, typing inside #### etc…)
	* strip all specials from the HTML prior to exporting

###Export

* Export to ePub

* Check if there is an alternative to `writePDFInsideRect:(NSRect)aRect toPasteboard:(NSPasteboard *)pboard`

* Find a way to support pagination for PDFs or eBook formats

* QuickLook for mdown

* Last line in textview looks truncated---maybe need an extra line?

* CSS selection should be saved (per doc / per user pref?)
