(function($){
$(document).ready(function(){

    $(".sidebar-left li a").click(function(e){
        e.preventDefault(); //To prevent the default anchor tag behaviour
        var url = this.href;
        $(".main").load(url);
    });
});
})(jQuery);
