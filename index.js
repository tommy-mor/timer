//TODO add adjacent combiner
//make it so it adds at next open hour, one hour
//add persistence somehow (start with browser memory, then accounts)
//add type list decider
//add submitter for month
//add login/storage maybe (for friends)
//add stats page
//data export

// DOM element where the Timeline will be attached
var container = document.getElementById('visualization');

// Create a DataSet (allows two way data-binding)
var timelineItems = new vis.DataSet([
]);

//time categories, add button
var categories;
if (localStorage.getItem('t-categories') == null) {
    categories = [];
    localStorage.setItem('t-categories', JSON.stringify(categories));
} else {
    categories = JSON.parse(localStorage.getItem('t-categories'));
}

var style = document.createElement('style');
style.type = 'text/css';
style.innerHTML = '';
document.getElementsByTagName('head')[0].appendChild(style);

let stub = document.getElementById('stubForButtons');
function render() {
    stub.innerHTML = '';
    categories.forEach((category) => {
        style.innerHTML = style.innerHTML + '\n';
        style.innerHTML = style.innerHTML + '.' + 't-' + category.name + ' { background-color: #' + category.color + '; }';
        var label = document.createElement("div");
        label.setAttribute("class", 't-' + category.class + " label");
        label.innerHTML = category.name;
        var button = document.createElement("button");
        button.setAttribute("onClick", "addNext(\"" + category.name + "\")");
        button.innerHTML = "add";
        button.setAttribute("class", "buttonright");
        label.append(button);
        var button2 = document.createElement("button");
        button2.setAttribute("onClick", "removeCategory(\"" + category.name + "\")");
        button2.innerHTML = "x";
        button2.setAttribute("class", "buttonright");
        label.append(button2);
        label.append(button);
        stub.appendChild(label);
    });
}
render();

// Configuration for the Timeline
var options = {
    snap: function(date, scale, step) {
        var fifteen = 60 * 60 * 1000 / 4;
        return Math.round(date / fifteen) * fifteen;

    },
    editable: true,
    maxMinorChars: 5,
    onUpdate: function(item, callback) {
        //check if there are collisions
        if (true) {
            console.log(item)
            callback(item)
        } else {
            //there is collision
            callback(null)
        }
    },
    onMove: function(item, callback) {

        //check if it collides with anyone else
        timelineItems.forEach((otherItem) => {
            if (item.id != otherItem.id) { //dont collide with self
                //first case is to determine if we are before or after new item, second case
                // is for the actual fail case
                if (item.end > otherItem.end && item.start < otherItem.end) callback(null)
                if (item.start < otherItem.start && item.end > otherItem.start) callback(null)
                if (item.start > otherItem.start && item.end < otherItem.end) callback(null)
            }
        })
    },

    onMoving: function(item, callback) {
        timelineItems.forEach((otherItem) => {
            if (item.id != otherItem.id) { //dont collide with self
                //first case is to determine if we are before or after new item, second case
                // is for the actual fail case
                if (item.end > otherItem.end && item.start < otherItem.end)
                    item.start = otherItem.end;
                if (item.start < otherItem.start && item.end > otherItem.start)
                    item.end = otherItem.start;
            }
        })
        let min = moment().startOf('day');
        let max = moment().startOf('day').add(1, 'days');

        if (item.start < min) item.start = min;
        if (item.start > max) item.start = max;
        if (item.end > max) item.end = max;

        timelineItems.update(item)
        callback(item); // send back the (possibly) changed item
    },
    stack: false,
    zoomable: false,
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
        subgroup: 'sg_2',
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
function addNext(name) {
    console.log(name)
    var nitem = {
        id: new Date(),
        type: 'range',
        content: 'new event',
        subgroup: 'sg_2',
        className: 'green'
        //content: event.target.innerHTML.split('-')[0].trim()
    };

    nitem.start = (moment().toDate());
    nitem.end = (moment() + moment().add(1, 'hour'));
    timeline.itemsData.add({ start: moment(), type: "range", end: moment().add(1, 'hour') });
}

function newCategory() {
    var name = document.getElementById("name").value;
    var color = document.getElementById("color").value;
    if (name == '') {
        alert('make sure name is not empty');
        return
    }
    categories.push({ name: name, class: name, color: color })
    //make sure the class is also saved in browser storage
    localStorage.setItem('t-categories', JSON.stringify(categories));
    render();
}

function removeCategory(name) {
    categories = categories.filter((cat) => cat.name != name)
    localStorage.setItem('t-categories', JSON.stringify(categories));
    render();
}
// Create a Timeline
var timeline = new vis.Timeline(container, timelineItems, options);

//timeline.on('select', function )
