({
    closeDropdown : function(component) {
        component.set("v.result", null);
        var dropdownBox = component.find("dropdown-box");
        if (dropdownBox) {
            dropdownBox.destroy();
        }
        else {
            var dropdownElement = component.get("v.dropdownElement");
            if (dropdownElement) {
                dropdownElement.remove();
            }
            else  {
                var dropdownId = component.get("v.id");
                dropdownBox = document.getElementById(dropdownId);
                if (dropdownBox) {
                    dropdownBox.remove();
                }
            }
        }
        this.fireLookupInputDropdownClosedEvent(component);
    },
    fireLookupInputDropdownClosedEvent : function(component) {
        var onclose = component.getEvent("onclose");
        onclose.fire();
    }
});