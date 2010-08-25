$(document).ready(function(){
	
  $("#api-test").submit( function() {
	var query = {
	  "query": $("#query").val(),
	  "limit": $("#limit").val(),
	  "type": $("#type").val()
	};
	window.location = "" + $("#store").val() + "/reconcile?query=" + escape( JSON.stringify(query) );
	return false;
  });
  
});
