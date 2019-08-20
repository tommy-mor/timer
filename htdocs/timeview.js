//TODO add adjacent combiner
//make it so it adds at next open hour, one hour
//add persistence somehow (start with browser memory, then accounts)
//add type list decider
//add submitter for month
//add login/storage maybe (for friends)
//add stats page
//data export
//todo add category label option

// DOM element where the Timeline will be attached
var container = document.getElementById('visualization');
var username = document.getElementById('username').value;
let day = document.getElementById('day').value;
let t = moment(day).hours(0).minutes(0);

//load data

//todo fix new items not being added to right day.

categories = {};
$.get('/categories').then((data) => {
    data.forEach(category => {
        console.log(category);
        categories[category.categoryid] = category;
    })
    render();
    return $.get('/day/' + username + '/' + t.format('YYYY-MM-DD') + 'T00:00:00.000')
        .then(x => x);

}).done((x) => {

    console.log('day');
    console.log(x);
    x.forEach((newItem) => {
        console.log(categories[newItem.categoryid].name);
        timeline.itemsData.add({ start: moment(newItem.start), type: "range", end: moment(newItem.end), className: 't-' + categories[newItem.categoryid].name, timechunkid: newItem.timechunkid });

    });
})


function navigateDay() {
    var username = document.getElementById('username').value;
    let day = moment(document.getElementById('day').value).format('YYYY-MM-DD');
    let t = moment(day).hours(0).minutes(0);

    window.location.href = '/v/' + username + '/' + day;

    console.log(t);
}

// Create a DataSet (allows two way data-binding)
var timelineItems = new vis.DataSet([
]);


var style = document.createElement('style');
style.type = 'text/css';
style.innerHTML = '';
document.getElementsByTagName('head')[0].appendChild(style);

let stub = document.getElementById('stubForButtons');
function render() {
    stub.innerHTML = '';
    style.innerHTML = '';
    Object.entries(categories).forEach(([pk, category]) => {
        console.log(category)
        style.innerHTML = style.innerHTML + '\n';
        //style.innerHTML = style.innerHTML + '.' + 't-' + category.name + ' { background-color: #' + category.color + '; border-color: #' + category.color + ';}';
        style.innerHTML = style.innerHTML + '.' + 't-' + category.name + ' { background-color: #' + category.color + '; border-color: rgba(0,0,0,.3)}';
        var label = document.createElement("div");
        label.setAttribute("class", 't-' + category.name + " label");
        label.innerHTML = category.name;
        var button = document.createElement("button");
        button.setAttribute("onClick", "addNext(\"" + category.name + "\")");
        button.innerHTML = "add";
        button.setAttribute("class", "buttonright");
        label.append(button);
        var button2 = document.createElement("button");
        button2.setAttribute("onClick", "removeCategory(" + pk + ")");
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
        callback(item)
    },
    onAdd: function(item, callback) {
        //disable adding double click items
        callback(null);
    },
    onMove: function(item, callback) { //TODO fix
        let works = true;
        //check if it collides with anyone else
        timelineItems.forEach((otherItem) => {
            if (item.id != otherItem.id) { //dont collide with self
                //first case is to determine if we are before or after new item, second case
                // is for the actual fail case
                if (item.end > otherItem.end && item.start < otherItem.end) works = false;
                if (item.start < otherItem.start && item.end > otherItem.start) works = false;
                if (item.start > otherItem.start && item.end < otherItem.end) works = false;
            }
        })

        if (works) {
            console.log(item);
            $.post('/timechunk/update', {
                timechunkid: item.timechunkid,
                start: moment(item.start).format('YYYY-MM-DDTHH:mm:ss.SSS'),
                end: moment(item.end).format('YYYY-MM-DDTHH:mm:ss.SSS'),
            }).done((pk) => {
                console.log(pk);
            }).fail((pk) => {
                callback(null);
            });
        } else { callback(null) }
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
        let min = moment(day).startOf('day');
        let max = moment(day).startOf('day').add(1, 'days');

        if (item.start < min) item.start = min;
        if (item.start > max) item.start = max;
        if (item.end > max) item.end = max;

        timelineItems.update(item);
        callback(item); // send back the (possibly) changed item
    },
    onRemove: function(item, callback) {
        console.log(item);
        $.ajax({
            url: '/timechunk/remove/' + item.timechunkid, 'type': 'DELETE'
        }).done((x) => {
            callback(item);
        });
    },
    stack: false,
    zoomable: false,
    min: moment(day).startOf('day'),
    max: moment(day).startOf('day').add(1, 'days')
};

function addNext(name) {
    console.log(name)
    let [item, next] = findFirstItem(timelineItems);


    let start
    if (item) {
        start = moment(item.end); //moment because not move, they are reset to JS Date()'s
    } else {
        start = moment(day).startOf('day');
    }
    let end = moment(start).add(1, 'hour');
    if (next && end > moment(next.start)) { // we would overlap with next one
        end = moment(next.start);
    }

    //to do, disable adding off screen

    let username = document.getElementById('username').value;
    let cpk = Object.values(categories).find(cat => cat.name == name).categoryid;
    let startstring = start.format('YYYY-MM-DDTHH:mm:ss.SSS');
    let endstring = end.format('YYYY-MM-DDTHH:mm:ss.SSS');
    let daystring = moment(day).utc().format('YYYY-MM-DDT00:00:00.000')

    if (item && item.className == 't-' + name) {
        let startstring_extend = moment(item.start).format('YYYY-MM-DDTHH:mm:ss.SSS');
        //the previous item is the same as this one, glob them together (maybe make this optional)
        console.log('tom');
        console.log(item)

        $.post('/timechunk/update', {
            timechunkid: item.timechunkid, start: startstring_extend, end: endstring,
        }).done((pk) => {
            item.end = end;
            console.log(pk);
            timelineItems.update(item);
        });
    } else {
        $.post('/timechunk/add', {
            username: username, start: startstring, end: endstring,
            daystring: daystring,
            categoryid: cpk
        }).done((pk) => {
            console.log(pk);
            timeline.itemsData.add({
                start: start, type: "range", end: end, className: 't-' + name, timechunkid: pk,
            });
        });
    }
    //timeline.itemsData.add({ start: moment(), type: "range", end: moment().add(1, 'hour') });
}

function newCategory() {
    var name = document.getElementById("name").value;
    var color = document.getElementById("color").value;
    if (name == '') {
        alert('make sure name is not empty');
        return
    }
    if (name.indexOf(' ') != -1) {
        alert('make sure name does not have spaces');
        return
    }
    $.post('/category/add', { name: name, color: color }).done((pk) => {
        categories[pk] = { name: name, color: color, categoryid: pk }
        render();
    });
}

function removeCategory(pk) {
    $.ajax({ url: '/category/remove/' + pk, 'type': 'DELETE' }).done((x) => {
        console.log(x);
        delete categories[pk];
        render();
    });
}

function findFirstItem(dataSet) {
    //todo fix this shit i just broke
    console.log(dataSet.length)
    if (dataSet.length == 0) return [undefined, undefined]
    //chese way
    let arr = [];
    let starts = [];

    dataSet.forEach((item) => {
        arr.push(item);
        starts.push(moment(item.start));
    })

	/*
    if (!starts.find(start => moment(start).isSame(moment(day).startOf('day'))))
        return { className: '', end: moment(day).startOf('day') };
		*/

    //sort by start date, earliest dates first
    arr.sort((a, b) => moment(a.start) - moment(b.start));
    let itemIdx = arr.findIndex((event) => starts.find((start) => moment(start).isSame(moment(event.end))) == undefined);
    return [arr[itemIdx], arr[itemIdx + 1]];
}
// Create a Timeline
var timeline = new vis.Timeline(container, timelineItems, options);

//timeline.on('select', function )
