
// DOM element where the Timeline will be attached
var container = document.getElementById('visualization');

// Create a DataSet (allows two way data-binding)
var items = new vis.DataSet([
]);

// Configuration for the Timeline
var options = {
    editable: true,
    min: moment().startOf('day'),
    max: moment().startOf('day').add(1, 'days')
};

function press() {
    console.log('strst')
}

// Create a Timeline
var timeline = new vis.Timeline(container, items, options);
