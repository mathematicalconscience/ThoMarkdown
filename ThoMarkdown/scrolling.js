function getPosition(element)
/* der Aufruf dieser Funktion ermittelt die absoluten Koordinaten
 des Objekts element */
{
	var elem=element,tagname="",x=0,y=0;
	
	/* solange elem ein Objekt ist und die Eigenschaft offsetTop enthaelt
	 wird diese Schleife fuer das Element und all seine Offset-Eltern ausgefuehrt */
	while ((typeof(elem)=="object")&&(typeof(elem.tagName)!="undefined"))
	{
		y+=elem.offsetTop;     /* Offset des jeweiligen Elements addieren */
		x+=elem.offsetLeft;    /* Offset des jeweiligen Elements addieren */
		tagname=elem.tagName.toUpperCase(); /* tag-Name ermitteln, Grossbuchstaben */
		
		/* wenn beim Body-tag angekommen elem fuer Abbruch auf 0 setzen */
		if (tagname=="BODY")
			elem=0;
		
		/* wenn elem ein Objekt ist und offsetParent enthaelt
		 Offset-Elternelement ermitteln */
		if (typeof(elem)=="object")
			if (typeof(elem.offsetParent)=="object")
				elem=elem.offsetParent;
	}
	
	/* Objekt mit x und y zurueckgeben */
	position=new Object();
	position.x=x;
	position.y=y;
	return position;
}

function scrollToAnchor()
{
	elemRef = "JavascriptStinkt";
	anchorTags = window.document.getElementsByTagName( 'a' );
	for (i = 0; i<anchorTags.length;i++)
	{
		if (anchorTags[i].name == "caretPos")
			elemRef = anchorTags[i];
	}
	
	if (elemRef == "JavascriptStinkt")
		return;
	
	pos = getPosition(elemRef); 
	
	window.scrollTo(pos.x - window.innerWidth / 2, pos.y - window.innerHeight / 2); 
}