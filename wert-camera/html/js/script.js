var up = false;

function popupfunction(source) {
    if(!up){
        $('#popup').fadeIn('slow');
        $('.popupclass').fadeIn('slow');
        $('<img  src='+source+' style = "width:100%; height: 100%;">').appendTo('.popupclass')
        up = true
    }
}

function popdownfunction() { 
    if(up){
        $('#popup').fadeOut('slow');
        $('.popupclass').fadeOut('slow');
        $('.popupclass').html("");
        up = false
        $.post('https://wert-camera/Close', JSON.stringify({}));
    }
}


$(document).on('keydown', function() {
    switch(event.keyCode) {
        case 27: // ESCAPE
            popdownfunction()
            break;
    }
});

$(document).ready(function(){
    window.addEventListener('message', function(event) {
        switch(event.data.action) {
            case "Show":
                popupfunction(event.data.photo);
                break;
        }
    })
});