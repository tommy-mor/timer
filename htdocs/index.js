function navigateToPage() {
	var username = document.getElementById('username').value;
	let day = moment(document.getElementById('day').value).format('YYYY-MM-DD');
	if (username.length == 0) {
		alert('make sure to enter a username');
		return
	}
	if (username.indexOf(' ') != -1) {
		alert('username cannot have spaces');
		return
	}
	if (day == "Invalid date") {
		alert('make sure date is valid');
		return
	}

	window.location.href = '/v/' + username + '/' + day;
}
