//TODO set default zoom to be 1 hr.
//add buttons to add other types faster
//add coloring for types
//add type list decider
//add submitter for month
//prevent overlaps 
//add login/storage maybe (for friends)
//add stats page
//data export

// DOM element where the Timeline will be attached
var container = document.getElementById('visualization');

// Create a DataSet (allows two way data-binding)
var items = new vis.DataSet([
]);

// Configuration for the Timeline
var options = {
    snap: function(date, scale, step) {
        var fifteen = 60 * 60 * 1000 / 4;
        return Math.round(date / fifteen) * fifteen;

    },
    editable: true,
    onUpdate: function(item, callback) {
        //check if there are collisions
        if (true) {
            console.log('test')
            callback(item)
        } else {
            //there is collision
            callback(null)
        }
    },
    stack: false,
    min: moment().startOf('day'),
    max: moment().startOf('day').add(1, 'days')
};



function handleDragStart(event) {
    var dragSrcEl = event.target;

    event.dataTransfer.effectAllowed = 'move';
    var item = {
        id: new Date(),
        type: "range",
        content: event.target.innerHTML.trim(),
        subgroup: 'sg_2'
        //content: event.target.innerHTML.split('-')[0].trim()
    };

    //item.start = new Date();
    //item.end = new Date(1000 * 60 * 10 + (new Date()).valueOf());

    event.dataTransfer.setData("text", JSON.stringify(item));
}

function handleObjectItemDragStart(event) {
    var dragSrcEl = event.target;

    event.dataTransfer.effectAllowed = 'move';
    var objectItem = {
        content: 'objectItemData',
        target: 'item'
    };
    event.dataTransfer.setData("text", JSON.stringify(objectItem));
}

var items = document.querySelectorAll('.items .item');
var objectItems = document.querySelectorAll('.object-item');

for (var i = items.length - 1; i >= 0; i--) {
    var item = items[i];
    item.addEventListener('dragstart', handleDragStart.bind(this), false);
}

for (var i = objectItems.length - 1; i >= 0; i--) {
    var objectItem = objectItems[i];
    objectItem.addEventListener('dragstart', handleObjectItemDragStart.bind(this), false);
}
function press() {
    console.log('strst')
}

// Create a Timeline
var timeline = new vis.Timeline(container, items, options);

//timeline.on('select', function )
