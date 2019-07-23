function navigateToPage() {
	var username = document.getElementById('username').value;
	let day = moment(document.getElementById('day').value).format('YYYY-MM-DD');

	window.location.href = '/v/' + username + '/' + day;
}
