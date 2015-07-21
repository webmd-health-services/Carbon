
jQuery( document ).ready(function() {
    jQuery("#CommandsMenu > li").click( function() {
        var selectedLi = jQuery("#CommandsMenu li.selected")
        selectedLi.removeClass("selected");
        
        var selectedCmdID = selectedLi.attr("id").replace("MenuItem","");
        jQuery("#" + selectedCmdID).hide();
        
        var li = jQuery(this);
        li.addClass("selected");
        
        var id = li.attr( 'id' )
        id = id.replace('MenuItem','');
        
        jQuery('#' + id).show();
        
        return false;
    });
});