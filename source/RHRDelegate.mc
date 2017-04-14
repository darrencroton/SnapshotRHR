using Toybox.WatchUi as Ui;

class RHRDelegate extends Ui.BehaviorDelegate {

    var parentView;

    function initialize(view) {
        parentView = view;
    }

    function onSelect() {    
        parentView.StartTimer();
    }

    function onNextPage() {    
        parentView.NextPage();
    }

    function onPreviousPage() {    
        parentView.PreviousPage();
    }

	function onMenu() {    
		parentView.ResetHistory();
    }


}