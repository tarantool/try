$(".terminal").keyup(() => {
	$("html, body").animate({ scrollTop: $(document).height() }, "slow");
	return false;
});
