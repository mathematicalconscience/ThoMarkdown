function cursorAnimation()
{
	$("a.cursor").animate(
						  {
							opacity: 0
						  }, "fast", "swing").animate(
													  {
														opacity: 1
													  }, "fast", "swing");
}

$(document).ready(function()
{
	setInterval ( "cursorAnimation()", 1000 );
});
