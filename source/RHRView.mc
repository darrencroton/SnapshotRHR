using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Sensor as Sensor;
using Toybox.Attention as Attention;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Time as Time;


enum
{
    HISTORY0,
    HISTORY1,
    HISTORY2,
    HISTORY3,
    HISTORY4,
    HISTORY5,
    HISTORY6,
    HISTORY7,
    HISTORY8,
    HISTORY9,
    HISTORY10,
    HISTORY11,
    HISTORY12,
    HISTORY13,
    HISTORY14,
    HISTORY15,
    HISTORY16,
    HISTORY17,
    HISTORY18,
    HISTORY19,
    HISTORY20,
    HISTORY21,
    HISTORY22,
    HISTORY23,
    HISTORY24,
    HISTORY25,
    HISTORY26,
    HISTORY27,
    HISTORY28,
    HISTORY29,
    HISTORY30,
    HISTORY31
}


class RHRView extends Ui.View {

	hidden var history = new [32];
    hidden var pageSize = 4;

	var HR;
	var haveHR;
	var RHR;
	var RHRval;
	var timerGO;
	var timerCOUNT;
	var timerCOUNTmax;
    var page;
    var thisSession;

    var vibrateData1 = [new Attention.VibeProfile(100, 100),
                        new Attention.VibeProfile(100, 100),
                        new Attention.VibeProfile(100, 100)];

    var vibrateData2 = [new Attention.VibeProfile( 25, 100),
                        new Attention.VibeProfile(100, 100),
                        new Attention.VibeProfile( 25, 100),
                        new Attention.VibeProfile(100, 100)];


    function initialize() {
    
		Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );
		Sensor.enableSensorEvents( method(:onSensor) );
		
    	HR = "--";
    	haveHR = false;
    	RHR = "--";
    	RHRval = 1000;
    	timerGO = false;
    	timerCOUNT = 0;
    	timerCOUNTmax = 60;
        page = 0;
        thisSession = false;

        read_data();
        
    }


    // Load your resources here
    function onLayout(dc) {
    }


    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }


    // Update the view
    function onUpdate(dc) {

//        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
		dc.drawLine(0, 20, 215, 20);
		dc.drawLine(0, 90, 215, 90);

//        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

        dc.drawText(107.5, 0, Gfx.FONT_SMALL, "Resting Heart Rate", Gfx.TEXT_JUSTIFY_CENTER);

        dc.drawText(60, 66, Gfx.FONT_MEDIUM, "HR", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(155, 66, Gfx.FONT_MEDIUM, "RHR", Gfx.TEXT_JUSTIFY_CENTER);
		
        dc.drawText(60, 15, Gfx.FONT_NUMBER_HOT, HR, Gfx.TEXT_JUSTIFY_CENTER);
        
        if (timerGO == false && timerCOUNT > 0) {
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        }

        dc.drawText(155, 15, Gfx.FONT_NUMBER_HOT, RHR, Gfx.TEXT_JUSTIFY_CENTER);

//        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

		if (page == 0) {

			dc.setPenWidth(3);
			var plotVals = new [history.size()];
			var i, length, value;

			var minimum = 1000;
			var maximum = 0;
			var dataStr;

			for (i = 0; i < history.size(); ++i) {

				length = history[i].length();
				dataStr = history[i].substring(length-3,length);
				
				if (dataStr.equals(" --")) {
				
					plotVals[i] = -1;
					
				} else {
				
					plotVals[i] = dataStr.toNumber();
					
					if (plotVals[i] < minimum) {
						minimum = plotVals[i];
					}
					
					if (plotVals[i] > maximum) {
						maximum = plotVals[i];
					}
					
				}
			}

			length = history[0].length();
			value = history[0].substring(length-3,length);
			dc.drawText(107.5, 159, Gfx.FONT_TINY, "LAST: " + value + " bpm", Gfx.TEXT_JUSTIFY_CENTER);
			
			dc.drawText(18, 89, Gfx.FONT_TINY, "min", Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawText(197, 89, Gfx.FONT_TINY, "max", Gfx.TEXT_JUSTIFY_CENTER);
			
			if (minimum <= maximum) {
				dc.drawText(18, 102, Gfx.FONT_TINY, "" + minimum, Gfx.TEXT_JUSTIFY_CENTER);
				dc.drawText(197, 102, Gfx.FONT_TINY, "" + maximum, Gfx.TEXT_JUSTIFY_CENTER);
			} else {
				dc.drawText(18, 102, Gfx.FONT_TINY, "--", Gfx.TEXT_JUSTIFY_CENTER);
				dc.drawText(197, 102, Gfx.FONT_TINY, "--", Gfx.TEXT_JUSTIFY_CENTER);
			}

			minimum = minimum * 0.99;
			maximum = maximum * 1.01;

			if (minimum < maximum) {
			
				dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				for (i = 0; i < plotVals.size()-1; ++i) {
				
	 				if(plotVals[i] != null && plotVals[i] > 0 && plotVals[i+1] != null && plotVals[i+1] > 0) {

						var data1x, data1y, data2x, data2y;
					
						data1x = 153 * (plotVals.size()-1 - i).toFloat() / (plotVals.size()-1).toFloat();
						data2x = 153 * (plotVals.size()-1 - (i+1)).toFloat() / (plotVals.size()-1).toFloat();
						data1y = 55 * (1 - (plotVals[i] - minimum).toFloat() / (maximum - minimum).toFloat());
						data2y = 55 * (1 - (plotVals[i+1] - minimum).toFloat() / (maximum - minimum).toFloat());

						dc.drawLine(30+data1x, 101+data1y, 30+data2x, 101+data2y);

					}
				
				}
			
			}

		} else {

			dc.drawText(107.5, 89, Gfx.FONT_MEDIUM, "History", Gfx.TEXT_JUSTIFY_CENTER);
		
			var shift = 16;
			var ystart = 111;
			var i = pageSize*(page-1);
			dc.drawText(107.5, ystart+shift*0, Gfx.FONT_TINY, "" + (i+1).toString() + ". " + history[i], Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawText(107.5, ystart+shift*1, Gfx.FONT_TINY, "" + (i+2).toString() + ". " + history[i+1], Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawText(107.5, ystart+shift*2, Gfx.FONT_TINY, "" + (i+3).toString() + ". " + history[i+2], Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawText(107.5, ystart+shift*3, Gfx.FONT_TINY, "" + (i+4).toString() + ". " + history[i+3], Gfx.TEXT_JUSTIFY_CENTER);

		}
    
    }


    function StartTimer()
    {
    
    	timerGO = true;
    	RHRval = 1000;
    	timerCOUNT = 0;
    	Attention.vibrate(vibrateData1);
    	
//    	Sys.println("push");

    }


    function NextPage()
    {
    
        page = page + 1;

        if (page > history.size()/pageSize) {
            page = 0;
        }

    }


    function PreviousPage()
    {
    
        page = page - 1;

        if (page < 0) {
            page = history.size()/pageSize;
        }

    }


    function ResetHistory() {

        var i;

        for (i=0; i<history.size()-1; i++) {
            history[i] = history[i+1];
        }
        history[history.size()-1] = "-- | --";

    	RHR = "--";
    	timerCOUNT = 0;
    	thisSession = false;

//        for (i=0; i<history.size(); i++) {
//			history[i] = "-- | --";
//		}

		copy_history();
		Attention.playTone(Attention.TONE_START);
		
		NextPage();
    }


    function onSensor(sensorInfo)
    {
        if( sensorInfo.heartRate != null ) {
        
        	if (haveHR == false) {
        		haveHR = true;
        		Attention.vibrate(vibrateData2);
        	}
        
            HR = sensorInfo.heartRate.toString();
            
            if (timerGO == true) {
            
//    			Sys.println("" + timerCOUNT);
            	timerCOUNT = timerCOUNT + 1;
            	
            	if (sensorInfo.heartRate < RHRval) {
            	
            		RHRval = sensorInfo.heartRate;
            		RHR = HR;
    			}
            	
            	if (timerCOUNT > timerCOUNTmax) {
            	
            		timerGO = false;
    				Attention.vibrate(vibrateData1);
					record_date();

            	}

            }
            
        } else {
            HR = "--";
            haveHR = false;
        }

        Ui.requestUpdate();
    }
 
 
 	function record_date() {

		var i;
		
		if (thisSession == false) {
			for (i=history.size()-1; i>0; i--) {
				history[i] = history[i-1];
			}
			thisSession = true;
		}

		var infoS = Calendar.info(Time.now(), Time.FORMAT_SHORT);
		var infoL = Calendar.info(Time.now(), Time.FORMAT_LONG);

		var dateStr = Lang.format("$1$ $2$/$3$", [infoL.day_of_week, infoS.day, infoS.month]);

		var timeStr;
		if (infoL.min.toNumber() > 9) {
			timeStr = Lang.format("$1$:$2$", [infoL.hour, infoL.min]);
		} else {
			timeStr = Lang.format("$1$:0$2$", [infoL.hour, infoL.min]);
		}		

		history[0] = dateStr + " " + timeStr + " | " + RHR;
		copy_history();					

 	}


    function read_data() {

        var i;
    
        var app = App.getApp();

		history[0] = app.getProperty(HISTORY0);
        history[1] = app.getProperty(HISTORY1);
        history[2] = app.getProperty(HISTORY2);
		history[3] = app.getProperty(HISTORY3);
		history[4] = app.getProperty(HISTORY4);
		history[5] = app.getProperty(HISTORY5);
		history[6] = app.getProperty(HISTORY6);
        history[7] = app.getProperty(HISTORY7);
        history[8] = app.getProperty(HISTORY8);
        history[9] = app.getProperty(HISTORY9);
        history[10] = app.getProperty(HISTORY10);
        history[11] = app.getProperty(HISTORY11);
        history[12] = app.getProperty(HISTORY12);
        history[13] = app.getProperty(HISTORY13);
        history[14] = app.getProperty(HISTORY14);
        history[15] = app.getProperty(HISTORY15);
        history[16] = app.getProperty(HISTORY16);
        history[17] = app.getProperty(HISTORY17);
        history[18] = app.getProperty(HISTORY18);
        history[19] = app.getProperty(HISTORY19);
        history[20] = app.getProperty(HISTORY20);
        history[21] = app.getProperty(HISTORY21);
        history[22] = app.getProperty(HISTORY22);
        history[23] = app.getProperty(HISTORY23);
        history[24] = app.getProperty(HISTORY24);
        history[25] = app.getProperty(HISTORY25);
        history[26] = app.getProperty(HISTORY26);
        history[27] = app.getProperty(HISTORY27);
        history[28] = app.getProperty(HISTORY28);
        history[29] = app.getProperty(HISTORY29);
        history[30] = app.getProperty(HISTORY30);
        history[31] = app.getProperty(HISTORY31);

        for (i=0; i<history.size(); i++) {

            if (history[i] == null) {
                history[i] = "-- | --";
            }

        }
             
    }


	function copy_history() {

        var app = App.getApp();

		app.setProperty(HISTORY31, history[31]);
		app.setProperty(HISTORY30, history[30]);
		app.setProperty(HISTORY29, history[29]);
		app.setProperty(HISTORY28, history[28]);
		app.setProperty(HISTORY27, history[27]);
		app.setProperty(HISTORY26, history[26]);
		app.setProperty(HISTORY25, history[25]);
		app.setProperty(HISTORY24, history[24]);
		app.setProperty(HISTORY23, history[23]);
		app.setProperty(HISTORY22, history[22]);
		app.setProperty(HISTORY21, history[21]);
		app.setProperty(HISTORY20, history[20]);
		app.setProperty(HISTORY19, history[19]);
		app.setProperty(HISTORY18, history[18]);
		app.setProperty(HISTORY17, history[17]);
		app.setProperty(HISTORY16, history[16]);
		app.setProperty(HISTORY15, history[15]);
		app.setProperty(HISTORY14, history[14]);
		app.setProperty(HISTORY13, history[13]);
		app.setProperty(HISTORY12, history[12]);
		app.setProperty(HISTORY11, history[11]);
		app.setProperty(HISTORY10, history[10]);
		app.setProperty(HISTORY9, history[9]);
		app.setProperty(HISTORY8, history[8]);
		app.setProperty(HISTORY7, history[7]);
		app.setProperty(HISTORY6, history[6]);
		app.setProperty(HISTORY5, history[5]);
		app.setProperty(HISTORY4, history[4]);
		app.setProperty(HISTORY3, history[3]);
		app.setProperty(HISTORY2, history[2]);
		app.setProperty(HISTORY1, history[1]);
		app.setProperty(HISTORY0, history[0]);
	
	}
	

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {    
    }

}
